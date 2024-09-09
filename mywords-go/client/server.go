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
	"sort"
	"strings"
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
func (s *Client) parseChartDateLevelCountMapFromGobFile(r io.ReadCloser) error {
	defer r.Close()
	b, err := io.ReadAll(r)
	if err != nil {
		return err
	}
	if len(b) == 0 {
		return nil
	}
	var chartDateLevelCountMap = make(map[string]map[mtype.WordKnownLevel]map[string]struct{})
	err = json.Unmarshal(b, &chartDateLevelCountMap)
	if err != nil {
		return err
	}
	// merge s.knownWordsMap and knownWordsMap
	for date, levelWordMap := range chartDateLevelCountMap {
		//if _, ok := s.chartDateLevelCountMap[date]; !ok {
		//	s.chartDateLevelCountMap[date] = make(map[WordKnownLevel]map[string]struct{})
		//}
		for level, wordMap := range levelWordMap {
			//if _, ok := s.chartDateLevelCountMap[date][level]; !ok {
			//	s.chartDateLevelCountMap[date][level] = make(map[string]struct{})
			//}
			for word := range wordMap {
				wp, _ := s.chartDateLevelCountMap.Get(date, level)
				wordMapNew := make(map[string]struct{}, len(wp))
				for k, v := range wp {
					wordMapNew[k] = v
				}
				wordMapNew[word] = struct{}{}
				s.chartDateLevelCountMap.Set(date, level, wordMapNew)
			}
		}
	}
	return s.saveChartDataFile()
}

// FixMyKnownWords .
func (s *Client) FixMyKnownWords() error {
	return nil
}

// SetProxyUrl .
func (s *Client) SetProxyUrl(proxyUrl string) error {
	return s.AllDao().KeyValueDao.UpdateOrCreateByKeyId(ctx, mtype.KeyIdProxy, proxyUrl)

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

func (s *Client) UpdateKnownWords(level mtype.WordKnownLevel, words ...string) error {

	for _, word := range words {
		//updateKnownWordCountLineChart must be ahead of updateKnownWords
		s.updateKnownWordCountLineChart(level, word)
	}
	err := s.updateKnownWords(level, words...)
	if err != nil {
		return err
	}

	if err = s.saveChartDataFile(); err != nil {
		return err
	}
	return nil

}
func (s *Client) updateKnownWords(level mtype.WordKnownLevel, words ...string) error {
	if len(words) == 0 {
		return nil
	}

	for _, word := range words {
		if word == "" {
			continue
		}
		firstLetter := strings.ToLower(word[:1])
		//if _, ok := s.knownWordsMap[firstLetter]; !ok {
		//	s.knownWordsMap[firstLetter] = make(map[string]WordKnownLevel)
		//}
		//s.knownWordsMap[firstLetter][word] = level
		s.knownWordsMap.Set(firstLetter, word, level)
	}
	//save to file
	return s.saveKnownWordsMapToFile()
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
	//if s.fileInfoMap == nil {
	//	s.fileInfoMap = make(map[string]FileInfo)
	//}
	//if s.fileInfoArchivedMap == nil {
	//	s.fileInfoArchivedMap = make(map[string]FileInfo)
	//}
	if _, ok := s.fileInfoArchivedMap.Get(fileName); ok {
		s.fileInfoArchivedMap.Set(fileName, fileInfo)
	} else {
		s.fileInfoMap.Set(fileName, fileInfo)
	}
	err = s.saveFileInfoMap()
	if err != nil {
		return err
	}
	return nil
}

func (s *Client) GetFileNameBySourceUrl(sourceUrl string) (string, bool) {
	var fileName string
	s.fileInfoMap.Range(func(key string, value model.FileInfo) bool {
		if sourceUrl == value.SourceUrl {
			fileName = value.FileName
			return false
		}
		return true
	})
	if fileName != "" {
		return fileName, true
	}
	//for _, info := range s.fileInfoMap {
	//	if info.SourceUrl == sourceUrl {
	//		return info.FileName, true
	//
	//	}
	//}

	s.fileInfoArchivedMap.Range(func(key string, value model.FileInfo) bool {
		if sourceUrl == value.SourceUrl {
			fileName = value.FileName
			return false
		}
		return true
	})

	if fileName != "" {
		return fileName, true
	}
	//for _, info := range s.fileInfoArchivedMap {
	//	if info.SourceUrl == sourceUrl {
	//		return info.FileName, true
	//	}
	//}
	return "", false
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
	for _, word := range words {
		firstLetter := strings.ToLower(word[:1])
		if l, ok := s.knownWordsMap.Get(firstLetter, word); ok {
			m[l]++
			continue
		}
		m[0]++
	}
	return m
}
func (s *Client) AllKnownWordMap() map[mtype.WordKnownLevel][]string {
	var m = make(map[mtype.WordKnownLevel][]string, 3)
	for _, wordLevelMap := range s.knownWordsMap.CopyData() {
		for word, level := range wordLevelMap {
			m[level] = append(m[level], word)
		}
	}
	for _, words := range m {
		sort.Slice(words, func(i, j int) bool {
			return words[i] < words[j]
		})
	}
	return m
}
func (s *Client) TodayKnownWordMap() map[mtype.WordKnownLevel][]string {
	var m = make(map[mtype.WordKnownLevel][]string, 3)
	today := time.Now().Format("2006-01-02")
	levelWordMap, _ := s.chartDateLevelCountMap.GetMapByKey(today)
	for level, wordLevelMap := range levelWordMap {
		for word := range wordLevelMap {
			m[level] = append(m[level], word)
		}
	}
	for _, words := range m {
		sort.Slice(words, func(i, j int) bool {
			return words[i] < words[j]
		})
	}
	return m
}

func (s *Client) ArticleFromGobFile(fileName string) (*artical.Article, error) {
	return s.articleFromGobFile(fileName)
}

func (s *Client) articleFromGobFile(fileName string) (*artical.Article, error) {
	path := filepath.Join(s.rootDataDir, dataDir, gobFileDir, fileName)
	b, err := os.ReadFile(path)
	if err != nil {
		_ = s.deleteGobFile(fileName)
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

// saveFileInfo .
func (s *Client) saveFileInfoMap() error {
	s.fileInfoArchivedMap.Range(func(key string, value model.FileInfo) bool {
		s.fileInfoMap.Delete(key)
		return true
	})
	//for name := range s.fileInfoArchivedMap {
	//	s.fileInfoMap.Delete(name)
	//	//if _, ok := s.fileInfoMap[name]; ok {
	//	//	delete(s.fileInfoMap, name)
	//	//}
	//}
	path := filepath.Join(s.rootDataDir, dataDir, fileInfoFile)
	b, _ := json.MarshalIndent(s.fileInfoMap.CopyData(), "", "  ")
	err := os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
	path = filepath.Join(s.rootDataDir, dataDir, fileInfosArchived)
	b, _ = json.MarshalIndent(s.fileInfoArchivedMap.CopyData(), "", "  ")
	err = os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
	return nil
}

// saveFileInfo .
func (s *Client) saveChartDataFile() error {
	path := filepath.Join(s.rootDataDir, dataDir, chartDataJsonFile)
	b, _ := json.MarshalIndent(s.chartDateLevelCountMap.CopyData(), "", "  ")
	err := os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
	return nil
}
