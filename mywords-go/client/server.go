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
	"mywords/dict"
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
	"unicode"
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
	dataDir = `data` // 存放背单词的目录
)

const (
	gobFileDir      = "gob_gz_files" // a.txt.gob, b.txt.gob, c.txt.gob ...
	gobGzFileSuffix = ".gob.gz"      // file_infos.json index file
	configFile      = "config.json"  // config.json
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

func (s *Client) netProxy() *url.URL {
	proxyUrl := s.cfg.Load().ProxyUrl
	if proxyUrl == "" {
		return nil
	}
	u, err := url.Parse(proxyUrl)
	if err != nil {
		return u
	}
	return u
}

func (s *Client) ProxyURL() string {
	return s.cfg.Load().ProxyUrl
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

// restoreFromBackUpDataKnownWordsFile delete gob file and update knownWordsMap
func (s *Client) restoreFromBackUpDataKnownWordsFile(f *zip.File) error {
	r, err := f.Open()
	if err != nil {
		return err
	}
	defer r.Close()
	b, err := io.ReadAll(r)
	if err != nil {
		return err
	}
	if len(b) == 0 {
		return nil
	}
	var knownWordsMap = make(map[string]map[string]mtype.WordKnownLevel)
	err = json.Unmarshal(b, &knownWordsMap)
	if err != nil {
		return err
	}
	// merge s.knownWordsMap and knownWordsMap
	for firstLetter, v := range knownWordsMap {
		for word, level := range v {
			//s.knownWordsMap[k][k1] = v1
			s.knownWordsMap.Set(firstLetter, word, level)
		}
	}
	return s.saveKnownWordsMapToFile()
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
		for _, f := range r.File {
			if filepath.Base(f.Name) == knownWordsFile {
				if err = s.restoreFromBackUpDataKnownWordsFile(f); err != nil {
					return err
				}
				break
			}
		}
	}
	var fileInfoMap map[string]model.FileInfo
	// restore file_infos.json
	for _, f := range r.File {
		if filepath.Base(f.Name) == fileInfoFile {
			fileInfoMap, err = s.restoreFromBackUpDataFileInfoFile(f)
			if err != nil {
				return err
			}
			break
		}
	}
	var fileInfoArchivedMap map[string]model.FileInfo
	for _, f := range r.File {
		if filepath.Base(f.Name) == fileInfosArchived {
			fileInfoArchivedMap, err = s.restoreFromBackUpDataFileInfoFile(f)
			if err != nil {
				return err
			}
			break
		}
	}

	if len(fileInfoMap) == 0 {
		return nil
	}
	var fileInfoMapOK = make(map[string]model.FileInfo)
	var fileInfoMapArchivedOK = make(map[string]model.FileInfo)

	// restore gob files
	for _, f := range r.File {
		k := filepath.Base(f.Name)
		if info, ok := fileInfoMap[k]; ok {
			if err = s.restoreFromBackUpDataFromAZipFile(f); err != nil {
				return err
			}
			fileInfoMapOK[k] = info
		} else if info, ok = fileInfoArchivedMap[k]; ok {
			if err = s.restoreFromBackUpDataFromAZipFile(f); err != nil {
				return err
			}
			fileInfoMapArchivedOK[k] = info
		}
	}
	// merge fileInfo
	for k, v := range fileInfoMapOK {
		//s.fileInfoMap[k] = v
		s.fileInfoMap.Set(k, v)
	}
	for k, v := range fileInfoMapArchivedOK {
		if syncByRemoteArchived {
			s.fileInfoArchivedMap.Set(k, v)
			continue
		}
		if _, ok := s.fileInfoMap.Get(k); !ok {
			//s.fileInfoMap[k] = v
			s.fileInfoMap.Set(k, v)

		}
	}

	if syncToadyWordCount {
		for _, file := range r.File {
			//chartDateLevelCountMap
			if filepath.Base(file.Name) == chartDataJsonFile {
				reader, err := file.Open()
				if err != nil {
					return err
				}
				if err = s.parseChartDateLevelCountMapFromGobFile(reader); err != nil {
					return err
				}
				break
			}
		}
	}

	for name, info := range fileInfoMap {
		//if _, ok := s.fileInfoMap[name]; ok {
		//	// ok means the file exists in s.fileInfoMap
		//	s.fileInfoMap[name] = info
		//}
		// update fileInfoMap mainly for LastModified
		if _, ok := s.fileInfoMap.Get(name); ok {
			// ok means the file exists in s.fileInfoMap

			s.fileInfoMap.Set(name, info)

		}
	}
	if syncByRemoteArchived {
		for name, info := range fileInfoArchivedMap {
			if _, ok := s.fileInfoMap.Get(name); ok {
				// ok means the file exists in s.fileInfoMap
				//delete(s.fileInfoMap, name)
				s.fileInfoMap.Delete(name)
				s.fileInfoArchivedMap.Set(name, info)
			} else if _, ok = s.fileInfoArchivedMap.Get(name); ok {
				// update fileInfoArchivedMap mainly for LastModified
				// ok means the file exists in s.fileInfoMap
				s.fileInfoArchivedMap.Set(name, info)
			}
		}
	}
	// 同步后如果归档文章中有，那么就删除
	if err = s.saveFileInfoMap(); err != nil {
		return err
	}
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

// KnownWordsMap .
func (s *Client) KnownWordsMap() map[string]map[string]mtype.WordKnownLevel {
	return s.knownWordsMap.CopyData()
}

// FixMyKnownWords .
func (s *Client) FixMyKnownWords() error {
	newMap := make(map[string]map[string]mtype.WordKnownLevel)
	for letter, wordLevelMap := range s.knownWordsMap.CopyData() {
		if _, ok := newMap[letter]; !ok {
			newMap[letter] = make(map[string]mtype.WordKnownLevel)
		}
		for word, level := range wordLevelMap {
			if unicode.IsUpper(rune(word[0])) {
				continue
			}
			if dict.WordLinkMap[word] != "" {
				newMap[letter][dict.WordLinkMap[word]] = level
			} else {
				newMap[letter][word] = level
			}
		}
	}
	s.knownWordsMap.Replace(newMap)
	return s.saveKnownWordsMapToFile()
}

// SetProxyUrl .
func (s *Client) SetProxyUrl(proxyUrl string) error {
	cfg := s.cfg.Load()
	cfgNew := new(config)
	*cfgNew = *cfg
	if proxyUrl == "" {
		cfgNew.ProxyUrl = ""
		s.cfg.Store(cfgNew)
		return s.saveConfig()
	}
	_, err := url.Parse(proxyUrl)
	if err != nil {
		return err
	}
	cfgNew.ProxyUrl = proxyUrl
	s.cfg.Store(cfgNew)
	return s.saveConfig()
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

// saveKnownWordsMapToFile save knownWordsMap to file
func (s *Client) saveKnownWordsMapToFile() error {
	//save to file
	b, _ := json.MarshalIndent(s.knownWordsMap.CopyData(), "", "  ")
	path := filepath.Join(s.rootDataDir, dataDir, knownWordsFile)
	err := os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
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
func (s *Client) ParseAndSaveArticleFromSourceUrl(sourceUrl string) (*artical.Article, error) {
	art, err := artical.ParseSourceUrl(sourceUrl, s.xpathExpr, s.netProxy())
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
		Title:        art.Title,
		SourceUrl:    sourceUrl,
		FileName:     fileName,
		Size:         int64(fileSize),
		LastModified: lastModified,
		IsDir:        false,
		TotalCount:   art.TotalCount,
		NetCount:     art.NetCount,
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

func (s *Client) ShowFileInfoList() []model.FileInfo {
	var items = make([]model.FileInfo, 0, s.fileInfoMap.Len())
	//for _, v := range s.fileInfoMap {
	//	items = append(items, v)
	//}
	s.fileInfoMap.Range(func(key string, value model.FileInfo) bool {
		items = append(items, value)
		return true
	})
	//sort by last modified
	sort.Slice(items, func(i, j int) bool {
		return items[i].LastModified > items[j].LastModified
	})
	return items
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

func (s *Client) GetArchivedFileInfoList() []model.FileInfo {
	var items = make([]model.FileInfo, 0, s.fileInfoArchivedMap.Len())
	s.fileInfoArchivedMap.Range(func(key string, value model.FileInfo) bool {
		items = append(items, value)
		return true
	})

	//for _, v := range s.fileInfoArchivedMap {
	//	items = append(items, v)
	//}
	//sort by last modified
	sort.Slice(items, func(i, j int) bool {
		return items[i].LastModified > items[j].LastModified
	})
	return items
}

func (s *Client) QueryWordLevel(word string) (mtype.WordKnownLevel, bool) {
	return s.queryWordLevel(word)
}
func (s *Client) queryWordLevel(word string) (mtype.WordKnownLevel, bool) {
	// check level
	if len(word) == 0 {
		return 0, false
	}
	firstLetter := strings.ToLower(word[:1])
	//if wordLevelMap, ok := s.knownWordsMap[firstLetter]; ok {
	//	if l, ok := wordLevelMap[word]; ok {
	//		return l, true
	//	}
	//}
	return s.knownWordsMap.Get(firstLetter, word)

}
func (s *Client) QueryWordsLevel(words ...string) map[string]mtype.WordKnownLevel {
	if len(words) == 0 {
		return map[string]mtype.WordKnownLevel{}
	}
	resultMap := make(map[string]mtype.WordKnownLevel, len(words))
	for _, word := range words {
		firstLetter := strings.ToLower(word[:1])
		if level, ok := s.knownWordsMap.Get(firstLetter, word); ok {
			resultMap[word] = level
		}
		//if wordLevelMap, ok := s.knownWordsMap[firstLetter]; ok {
		//	resultMap[word] = wordLevelMap[word]
		//}
	}
	return resultMap
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
func (s *Client) DeleteGobFile(fileName string) error {
	return s.deleteGobFile(fileName)
}
func (s *Client) deleteGobFile(fileName string) error {
	var err error
	s.fileInfoMap.Delete(fileName)
	//delete(s.fileInfoMap, fileName)
	//delete(s.fileInfoArchivedMap, fileName)
	s.fileInfoArchivedMap.Delete(fileName)

	err = s.saveFileInfoMap()
	if err != nil {
		return err
	}
	err = os.Remove(filepath.Join(s.rootDataDir, dataDir, gobFileDir, fileName))
	if err != nil {
		return err
	}

	return nil
}

// ArchiveGobFile archive the gob file
func (s *Client) ArchiveGobFile(fileName string) error {
	info, ok := s.fileInfoMap.Get(fileName)
	if !ok {
		return nil
	}
	s.fileInfoMap.Delete(fileName)
	//delete(s.fileInfoMap, fileName)
	info.LastModified = time.Now().UnixMilli()
	s.fileInfoArchivedMap.Set(fileName, info)
	if err := s.saveFileInfoMap(); err != nil {
		return err
	}
	return nil
}

// UnArchiveGobFile UnArchive the gob file
func (s *Client) UnArchiveGobFile(fileName string) error {
	info, ok := s.fileInfoArchivedMap.Get(fileName)
	if !ok {
		return nil
	}
	s.fileInfoArchivedMap.Delete(fileName)
	info.LastModified = time.Now().UnixMilli()
	s.fileInfoMap.Set(fileName, info)
	if err := s.saveFileInfoMap(); err != nil {
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

// saveConfig .
func (s *Client) saveConfig() error {
	path := filepath.Join(s.rootDataDir, configFile)
	b, _ := json.MarshalIndent(s.cfg.Load(), "", "  ")
	err := os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
	return nil
}
