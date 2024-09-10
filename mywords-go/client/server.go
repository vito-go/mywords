package client

import "C"
import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"context"
	"crypto/sha1"
	"encoding/gob"
	"encoding/json"
	"fmt"
	"github.com/antchfx/xpath"
	"golang.org/x/time/rate"
	"gorm.io/gorm"
	"io"
	"mywords/artical"
	"mywords/client/dao"
	"mywords/model"
	"mywords/model/mtype"
	"mywords/mylog"
	"mywords/pkg/db"
	"mywords/pkg/log"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"sync/atomic"
	"time"
)

type Client struct {
	rootDataDir string
	xpathExpr   string //must can compile
	//knownWordsMap map[string]map[string]WordKnownLevel // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//fileInfoMap1        map[string]FileInfo                  // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}

	mux           sync.Mutex //
	shareListener net.Listener
	shareOpen     *atomic.Bool
	// multicast

	//chartDateLevelCountMap map[string]map[WordKnownLevel]map[string]struct{} // date: {1: {"words":{}}, 2: 200, 3: 300}

	// 新字段

	rootDir string

	gdb             *gorm.DB
	dbPath          string
	allDao          *dao.AllDao
	codeContentChan chan CodeContent
	pprofListen     net.Listener //may be nil

	messageLimiter *rate.Limiter
	closed         atomic.Bool

	//		//
	//	//knownWordsMap map[string]map[string]WordKnownLevel // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//	knownWordsMap *MySyncMapMap[string, WordKnownLevel] // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//	//fileInfoMap1        map[string]FileInfo                  // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//	fileInfoMap         *MySyncMap[FileInfo] // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//	fileInfoArchivedMap *MySyncMap[FileInfo] // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//
	//	mux           sync.Mutex //
	//	shareListener net.Listener
	//	// multicast
	//	remoteHostMap sync.Map // remoteHost: port
	//
	//	//chartDateLevelCountMap map[string]map[WordKnownLevel]map[string]struct{} // date: {1: {"words":{}}, 2: 200, 3: 300}
	//	chartDateLevelCountMap *MySyncMapMap[WordKnownLevel, map[string]struct{}] // date: {1: {"words":{}}, 2: 200, 3: 300}

}

func (s *Client) AllDao() *dao.AllDao {
	return s.allDao
}

type config struct {
	ProxyUrl  string `json:"proxyUrl"`
	SharePort int    `json:"sharePort"`
	ShareCode int64  `json:"shareCode"`
}

func (c *config) Clone() *config {
	return &config{
		ProxyUrl:  c.ProxyUrl,
		SharePort: c.SharePort,
		ShareCode: c.ShareCode,
	}
}

const (
	dataDir         = `data`         // 存放背单词的目录
	gobFileDir      = "gob_gz_files" // a.txt.gob, b.txt.gob, c.txt.gob ...
	gobGzFileSuffix = ".gob.gz"      // file_infos.json index file
)

func NewServer(rootDataDir string) (*Client, error) {
	rootDataDir = filepath.ToSlash(rootDataDir)
	if err := os.MkdirAll(rootDataDir, 0755); err != nil {
		return nil, err
	}

	dbDir := filepath.ToSlash(filepath.Join(rootDataDir, DirDB))
	err := os.MkdirAll(dbDir, os.ModePerm)
	if err != nil {
		return nil, err
	}
	dbPath := filepath.ToSlash(filepath.Join(dbDir, "myproxy.db"))
	gdb, err := db.NewDB(dbPath)
	if err != nil {
		return nil, err
	}
	allDao := dao.NewAllDao(gdb)
	if err := os.MkdirAll(filepath.Join(rootDataDir, dataDir, gobFileDir), 0755); err != nil {
		return nil, err
	}

	client := &Client{rootDataDir: rootDataDir,
		xpathExpr:       artical.DefaultXpathExpr,
		allDao:          allDao,
		rootDir:         rootDataDir,
		gdb:             gdb,
		dbPath:          dbPath,
		codeContentChan: make(chan CodeContent, 1024),
		shareOpen:       &atomic.Bool{},
	}
	err = client.InitCreateTables()
	if err != nil {
		return nil, err
	}

	pprofLis, err := client.startPProf()
	if err != nil {
		return nil, err
	}
	client.pprofListen = pprofLis
	log.SetHook(func(ctx context.Context, record *log.HookRecord) {
		msg := record.Content
		if debug.Load() {
			client.SendCodeContent(CodeLog, msg)
		}
		level := record.Level

		if level == log.LevelError {

		} else if level == log.LevelWarn {

		}

	})
	return client, nil
}

// RootDataDir . root data dir
func (s *Client) RootDataDir() string {
	return s.rootDataDir
}

func (s *Client) DataDir() string {
	return filepath.ToSlash(filepath.Join(s.rootDataDir, dataDir))
}

func (s *Client) netProxy(ctx context.Context) *url.URL {
	proxy, err := s.allDao.KeyValueDao.Proxy(ctx)
	if err != nil {
		return nil
	}

	u, err := url.Parse(proxy)
	if err != nil {
		return nil
	}
	return u
}

func (s *Client) ProxyURL() string {
	u := s.netProxy(ctx)
	if u == nil {
		return ""
	}
	return u.String()
}

// restoreFromBackUpDataFromAZipFile delete gob file and update fileInfoMap
func (s *Client) restoreFromBackUpDataFromAZipFile(f *zip.File) error {
	r, err := f.Open()
	if err != nil {
		return err
	}
	defer r.Close()

	var buf bytes.Buffer
	_, err = io.Copy(&buf, r)
	if err != nil {
		return err
	}
	art, err := s.articleFromGobGZContent(buf.Bytes())
	if err != nil {
		return err
	}
	return s.saveArticle(art)
}

func (s *Client) restoreFromBackUpDataFileInfoFile(f *zip.File) (map[string]model.FileInfo, error) {
	r, err := f.Open()
	if err != nil {
		return nil, err
	}
	defer r.Close()
	b, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}
	if len(b) == 0 {
		return make(map[string]model.FileInfo), nil
	}
	var fileInfoMap = make(map[string]model.FileInfo)
	err = json.Unmarshal(b, &fileInfoMap)
	if err != nil {
		return nil, err
	}
	return fileInfoMap, nil
}

func (s *Client) RestoreFromBackUpData(syncKnownWords bool, backUpDataZipPath string, syncToadyWordCount bool, syncByRemoteArchived bool) error {
	return s.restoreFromBackUpData(syncKnownWords, backUpDataZipPath, syncToadyWordCount, syncByRemoteArchived)
}
func (s *Client) restoreFromBackUpData(syncKnownWords bool, backUpDataZipPath string, syncToadyWordCount bool, syncByRemoteArchived bool) error {
	r, err := zip.OpenReader(backUpDataZipPath)
	if err != nil {
		return err
	}
	defer r.Close()
	var fileMap = make(map[string]*zip.File)
	for _, f := range r.File {
		fileMap[f.Name] = f
	}

	if syncKnownWords {

		// TODO
	}
	// todo
	return nil
}

// FixMyKnownWords .
func (s *Client) FixMyKnownWords() error {
	return nil
}

// SetProxyUrl .
func (s *Client) SetProxyUrl(proxyUrl string) error {
	return s.AllDao().KeyValueDao.SetProxyURL(ctx, proxyUrl)

}

// SetXpathExpr . usually for debug
func (s *Client) SetXpathExpr(expr string) (err error) {
	if expr == "" {
		s.xpathExpr = artical.DefaultXpathExpr
		return nil
	}
	_, err = xpath.Compile(expr)
	if err != nil {
		return err
	}
	s.xpathExpr = expr
	return nil
}

func (s *Client) ParseAndSaveArticleFromSourceUrlAndContent(sourceUrl string, htmlContent []byte, lastModified int64) (*artical.Article, error) {
	art, err := artical.ParseContent(sourceUrl, s.xpathExpr, htmlContent, lastModified)
	if err != nil {
		return nil, err
	}
	err = s.saveArticle(art)
	if err != nil {
		return nil, err
	}
	return art, nil
}

var ctx = context.TODO()

func (s *Client) ParseAndSaveArticleFromSourceUrl(sourceUrl string) (*artical.Article, error) {
	art, err := artical.ParseSourceUrl(sourceUrl, s.xpathExpr, s.netProxy(ctx))
	if err != nil {
		return nil, err
	}
	err = s.saveArticle(art)
	if err != nil {
		return nil, err
	}
	mylog.Info("ParseAndSaveArticleFromSourceUrl", "sourceUrl", sourceUrl, "title", art.Title)
	return art, nil
}

func (s *Client) ParseAndSaveArticleFromFile(path string) (*artical.Article, error) {
	art, err := artical.ParseLocalFile(path)
	if err != nil {
		return nil, err
	}
	err = s.saveArticle(art)
	if err != nil {
		return nil, err
	}
	return art, nil
}

func (s *Client) saveArticle(art *artical.Article) error {
	lastModified := art.LastModified
	if lastModified <= 0 {
		lastModified = time.Now().UnixMilli()
	}
	sourceUrl := art.SourceUrl
	//gob marshal
	var buf bytes.Buffer
	err := gob.NewEncoder(&buf).Encode(art)
	if err != nil {
		return err
	}
	//save gob file
	fileName := fmt.Sprintf("%x%s", sha1.Sum([]byte(art.HTMLContent)), gobGzFileSuffix)
	path := filepath.Join(s.rootDataDir, dataDir, gobFileDir, fileName)
	var bufGZ bytes.Buffer
	gz := gzip.NewWriter(&bufGZ)
	fileSize, err := gz.Write(buf.Bytes())
	if err != nil {
		return err
	}
	err = gz.Close()
	if err != nil {
		return err
	}
	err = os.WriteFile(path, bufGZ.Bytes(), 0644)
	if err != nil {
		return err
	}
	// save FileInfo
	fileInfo := model.FileInfo{
		ID:           0,
		Title:        art.Title,
		SourceUrl:    sourceUrl,
		FileName:     fileName,
		Size:         int64(fileSize),
		LastModified: lastModified,
		IsDir:        false,
		TotalCount:   art.TotalCount,
		NetCount:     art.NetCount,
		Archived:     false,
		CreateAt:     time.Now().UnixMilli(),
		UpdateAt:     time.Now().UnixMilli(),
	}
	_, err = s.AllDao().FileInfoDao.Create(ctx, &fileInfo)
	return err
}

func (s *Client) QueryWordLevel(word string) (mtype.WordKnownLevel, bool) {
	// check level
	if len(word) == 0 {
		return 0, false
	}
	resultMap, err := s.QueryWordsLevel(word)
	if err != nil {
		return 0, false
	}
	if level, ok := resultMap[word]; ok {
		return level, true
	}
	return 0, false
}
func (s *Client) QueryWordsLevel(words ...string) (map[string]mtype.WordKnownLevel, error) {
	items, err := s.allDao.KnownWordsDao.ItemsByWords(ctx, words...)
	if err != nil {
		return nil, err
	}
	resultMap := make(map[string]mtype.WordKnownLevel, len(words))
	for _, item := range items {
		resultMap[item.Word] = item.Level
	}
	return resultMap, nil
}

func (s *Client) LevelDistribute(words []string) map[mtype.WordKnownLevel]int {
	var m = make(map[mtype.WordKnownLevel]int, 3)
	items, err := s.allDao.KnownWordsDao.ItemsByWords(ctx, words...)
	if err != nil {
		return nil
	}
	for _, item := range items {
		if item.Level == 0 {
			continue
		}
		m[item.Level]++
	}
	return m
}
func (s *Client) AllKnownWordMap() map[mtype.WordKnownLevel][]string {
	items, err := s.allDao.KnownWordsDao.AllItems(ctx)
	if err != nil {
		return nil
	}
	var resultMap = make(map[mtype.WordKnownLevel][]string, 3)
	for _, item := range items {
		resultMap[item.Level] = append(resultMap[item.Level], item.Word)
	}
	return resultMap
}
func (s *Client) TodayKnownWordMap() map[mtype.WordKnownLevel][]string {
	createDay, _ := strconv.ParseInt(time.Now().Format("2006-01-02"), 10, 64)
	items, err := s.allDao.KnownWordsDao.AllItemsByCreateDay(ctx, createDay)
	if err != nil {
		return nil
	}
	var resultMap = make(map[mtype.WordKnownLevel][]string, 3)
	for _, item := range items {
		resultMap[item.Level] = append(resultMap[item.Level], item.Word)
	}
	return resultMap
}

func (s *Client) ArticleFromFileInfo(fileInfo *model.FileInfo) (*artical.Article, error) {
	fileName := fileInfo.FileName
	id := fileInfo.ID
	path := filepath.Join(s.rootDataDir, dataDir, gobFileDir, fileName)
	b, err := os.ReadFile(path)
	if err != nil {
		_ = s.deleteGobFile(id)
		return nil, err
	}
	return s.articleFromGobGZContent(b)

}

func (s *Client) articleFromGobGZContent(b []byte) (*artical.Article, error) {
	gzReader, err := gzip.NewReader(bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	defer gzReader.Close()
	var art artical.Article
	//gob unmarshal
	err = gob.NewDecoder(gzReader).Decode(&art)
	if err != nil {
		return nil, err
	}
	return &art, nil
}

// DeleteGobFile delete gob file and update fileInfoMap
func (s *Client) DeleteGobFile(id int64) error {
	return s.deleteGobFile(id)
}
func (s *Client) deleteGobFile(id int64) error {
	item, err := s.AllDao().FileInfoDao.ItemByID(ctx, id)
	if err != nil {
		return err
	}
	_, err = s.AllDao().FileInfoDao.DeleteById(ctx, item.ID)
	if err != nil {
		return err
	}
	fileName := item.FileName
	err = os.Remove(filepath.Join(s.rootDataDir, dataDir, gobFileDir, fileName))
	if err != nil {
		return err
	}
	return nil
}
