package server

import "C"
import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"crypto/sha1"
	"encoding/gob"
	"encoding/json"
	"fmt"
	"github.com/antchfx/xpath"
	"io"
	"mywords/artical"
	"mywords/dict"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode"
)

type WordKnownLevel int // from 1 to 3, 3 stands for the most known. zero means unknown.

func (w WordKnownLevel) Name() string {

	return fmt.Sprintf("%d级", w)
}

type Server struct {
	rootDataDir string
	xpathExpr   string   //must can compile
	proxy       *url.URL // it can be nil if no proxy
	//
	knownWordsMap       map[string]map[string]WordKnownLevel // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	fileInfoMap         map[string]FileInfo                  // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	fileInfoArchivedMap map[string]FileInfo                  // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}

	mux           sync.Mutex //
	shareListener net.Listener
	// multicast
	remoteHostMap sync.Map // remoteHost: port

	chartDateLevelCountMap map[string]map[WordKnownLevel]map[string]struct{} // date: {1: {"words":{}}, 2: 200, 3: 300}
}

const (
	dataDir           = `data`                     // 存放背单词的目录
	gobFileDir        = "gob_gz_files"             // a.txt.gob, b.txt.gob, c.txt.gob ...
	knownWordsFile    = "known_words.json"         // all known words
	fileInfoFile      = "file_infos.json"          // file_infos.json index file
	chartDataJsonFile = "daily_chart_data.json"    // daily_chart_data.json daily chart data
	gobGzFileSuffix   = ".gob.gz"                  // file_infos.json index file
	fileInfosArchived = "file_infos_archived.json" // file_infos_archived.json index file
)

func NewServer(rootDataDir string, proxyUrl string) (*Server, error) {
	rootDataDir = filepath.ToSlash(rootDataDir)
	if err := os.MkdirAll(rootDataDir, 0755); err != nil {
		return nil, err
	}
	if err := os.MkdirAll(filepath.Join(rootDataDir, dataDir, gobFileDir), 0755); err != nil {
		return nil, err
	}
	b, err := os.ReadFile(filepath.Join(rootDataDir, dataDir, fileInfoFile))
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	fileInfoMap := make(map[string]FileInfo)
	if len(b) > 0 {
		err = json.Unmarshal(b, &fileInfoMap)
		if err != nil {
			return nil, err
		}
	}
	b, err = os.ReadFile(filepath.Join(rootDataDir, dataDir, fileInfosArchived))
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	fileInfoArchivedMap := make(map[string]FileInfo)
	if len(b) > 0 {
		err = json.Unmarshal(b, &fileInfoArchivedMap)
		if err != nil {
			return nil, err
		}
	}

	b, err = os.ReadFile(filepath.Join(rootDataDir, dataDir, knownWordsFile))
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	knownWordsMap := make(map[string]map[string]WordKnownLevel)
	if len(b) > 0 {
		err = json.Unmarshal(b, &knownWordsMap)
		if err != nil {
			return nil, err
		}
	}
	var proxy *url.URL
	if proxyUrl != "" {
		proxy, err = url.Parse(proxyUrl)
		if err != nil {
			return nil, err
		}
	}

	var chartDateLevelCountMap = make(map[string]map[WordKnownLevel]map[string]struct{})
	b, err = os.ReadFile(filepath.Join(rootDataDir, dataDir, chartDataJsonFile))
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	if len(b) > 0 {
		err = json.Unmarshal(b, &chartDateLevelCountMap)
		if err != nil {
			return nil, err
		}
	}
	s := &Server{rootDataDir: rootDataDir,
		knownWordsMap:          knownWordsMap,
		fileInfoMap:            fileInfoMap,
		proxy:                  proxy,
		xpathExpr:              artical.DefaultXpathExpr,
		chartDateLevelCountMap: chartDateLevelCountMap,
		fileInfoArchivedMap:    fileInfoArchivedMap,
	}
	return s, nil
}

// restoreFromBackUpDataFromAZipFile delete gob file and update fileInfoMap
func (s *Server) restoreFromBackUpDataFromAZipFile(f *zip.File) error {
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

func (s *Server) restoreFromBackUpDataFileInfoFile(f *zip.File) (map[string]FileInfo, error) {
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
		return make(map[string]FileInfo), nil
	}
	var fileInfoMap = make(map[string]FileInfo)
	err = json.Unmarshal(b, &fileInfoMap)
	if err != nil {
		return nil, err
	}
	return fileInfoMap, nil
}

// restoreFromBackUpDataKnownWordsFile delete gob file and update knownWordsMap
func (s *Server) restoreFromBackUpDataKnownWordsFile(f *zip.File) error {
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
	var knownWordsMap = make(map[string]map[string]WordKnownLevel)
	err = json.Unmarshal(b, &knownWordsMap)
	if err != nil {
		return err
	}
	// merge s.knownWordsMap and knownWordsMap
	for k, v := range knownWordsMap {
		if _, ok := s.knownWordsMap[k]; !ok {
			s.knownWordsMap[k] = make(map[string]WordKnownLevel)
		}
		for k1, v1 := range v {
			s.knownWordsMap[k][k1] = v1
		}
	}
	return s.saveKnownWordsMapToFile()
}

func (s *Server) RestoreFromBackUpData(syncKnownWords bool, backUpDataZipPath string, syncToadyWordCount bool) error {
	return s.restoreFromBackUpData(syncKnownWords, backUpDataZipPath, syncToadyWordCount)
}
func (s *Server) restoreFromBackUpData(syncKnownWords bool, backUpDataZipPath string, syncToadyWordCount bool) error {
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
	var fileInfoMap map[string]FileInfo
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
	var fileInfoArchivedMap map[string]FileInfo
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
	var fileInfoMapOK = make(map[string]FileInfo)
	var fileInfoMapArchivedOK = make(map[string]FileInfo)

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
		s.fileInfoMap[k] = v
	}
	for k, v := range fileInfoMapArchivedOK {
		s.fileInfoArchivedMap[k] = v
	}

	if syncToadyWordCount {
		for _, file := range r.File {
			//chartDateLevelCountMap
			if filepath.Base(file.Name) == chartDataJsonFile {
				reader, err := file.Open()
				if err != nil {
					return err
				}
				err = s.parseChartDateLevelCountMapFromGobFile(reader)
				if err != nil {
					return err
				}
				break
			}
		}
	}

	for name, info := range fileInfoMap {
		// update fileInfoMap mainly for LastModified
		if _, ok := s.fileInfoMap[name]; ok {
			// ok means the file exists in s.fileInfoMap
			s.fileInfoMap[name] = info
		}
	}
	for name, info := range fileInfoArchivedMap {
		if _, ok := s.fileInfoMap[name]; ok {
			// ok means the file exists in s.fileInfoMap
			delete(s.fileInfoMap, name)
			s.fileInfoArchivedMap[name] = info
		} else if _, ok = s.fileInfoArchivedMap[name]; ok {
			// update fileInfoArchivedMap mainly for LastModified
			// ok means the file exists in s.fileInfoMap
			s.fileInfoArchivedMap[name] = info
		}
	}
	// 同步后如果归档文章中有，那么就删除
	if err = s.saveFileInfoMap(); err != nil {
		return err
	}
	return nil
}
func (s *Server) parseChartDateLevelCountMapFromGobFile(r io.ReadCloser) error {
	defer r.Close()
	b, err := io.ReadAll(r)
	if err != nil {
		return err
	}
	if len(b) == 0 {
		return nil
	}
	var chartDateLevelCountMap = make(map[string]map[WordKnownLevel]map[string]struct{})
	err = json.Unmarshal(b, &chartDateLevelCountMap)
	if err != nil {
		return err
	}
	// merge s.knownWordsMap and knownWordsMap
	for date, levelWordMap := range chartDateLevelCountMap {
		if _, ok := s.chartDateLevelCountMap[date]; !ok {
			s.chartDateLevelCountMap[date] = make(map[WordKnownLevel]map[string]struct{})
		}
		for level, wordMap := range levelWordMap {
			if _, ok := s.chartDateLevelCountMap[date][level]; !ok {
				s.chartDateLevelCountMap[date][level] = make(map[string]struct{})
			}
			for word := range wordMap {
				s.chartDateLevelCountMap[date][level][word] = struct{}{}
			}
		}
	}
	return s.saveChartDataFile()
}

// KnownWordsMap .
func (s *Server) KnownWordsMap() map[string]map[string]WordKnownLevel {
	return s.knownWordsMap
}

// FixMyKnownWords .
func (s *Server) FixMyKnownWords() error {
	newMap := make(map[string]map[string]WordKnownLevel)
	for letter, wordLevelMap := range s.knownWordsMap {
		if _, ok := newMap[letter]; !ok {
			newMap[letter] = make(map[string]WordKnownLevel)
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
	s.knownWordsMap = newMap
	return s.saveKnownWordsMapToFile()
}

// SetProxyUrl .
func (s *Server) SetProxyUrl(proxyUrl string) (err error) {
	if proxyUrl == "" {
		s.proxy = nil
		return nil
	}
	proxy, err := url.Parse(proxyUrl)
	if err != nil {
		return err
	}
	s.proxy = proxy
	return nil
}

// SetXpathExpr . usually for debug
func (s *Server) SetXpathExpr(expr string) (err error) {
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

func (s *Server) UpdateKnownWords(level WordKnownLevel, words ...string) error {
	s.mux.Lock()
	defer s.mux.Unlock()
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
func (s *Server) updateKnownWords(level WordKnownLevel, words ...string) error {
	if len(words) == 0 {
		return nil
	}
	if s.knownWordsMap == nil {
		s.knownWordsMap = make(map[string]map[string]WordKnownLevel)
	}
	for _, word := range words {
		if word == "" {
			continue
		}
		firstLetter := strings.ToLower(word[:1])
		if _, ok := s.knownWordsMap[firstLetter]; !ok {
			s.knownWordsMap[firstLetter] = make(map[string]WordKnownLevel)
		}
		s.knownWordsMap[firstLetter][word] = level
	}
	//save to file
	return s.saveKnownWordsMapToFile()
}

// saveKnownWordsMapToFile save knownWordsMap to file
func (s *Server) saveKnownWordsMapToFile() error {
	//save to file
	b, _ := json.MarshalIndent(s.knownWordsMap, "", "  ")
	path := filepath.Join(s.rootDataDir, dataDir, knownWordsFile)
	err := os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
	return nil
}

func (s *Server) ParseAndSaveArticleFromSourceUrlAndContent(sourceUrl string, htmlContent []byte, lastModified int64) (*artical.Article, error) {
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
func (s *Server) ParseAndSaveArticleFromSourceUrl(sourceUrl string) (*artical.Article, error) {
	art, err := artical.ParseSourceUrl(sourceUrl, s.xpathExpr, s.proxy)
	if err != nil {
		return nil, err
	}
	err = s.saveArticle(art)
	if err != nil {
		return nil, err
	}
	return art, nil
}
func (s *Server) saveArticle(art *artical.Article) error {
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
	fileInfo := FileInfo{
		Title:        art.Title,
		SourceUrl:    sourceUrl,
		FileName:     fileName,
		Size:         int64(fileSize),
		LastModified: lastModified,
		IsDir:        false,
		TotalCount:   art.TotalCount,
		NetCount:     art.NetCount,
	}
	if s.fileInfoMap == nil {
		s.fileInfoMap = make(map[string]FileInfo)
	}
	if s.fileInfoArchivedMap == nil {
		s.fileInfoArchivedMap = make(map[string]FileInfo)
	}
	if _, ok := s.fileInfoArchivedMap[fileName]; ok {
		s.fileInfoArchivedMap[fileName] = fileInfo
	} else {
		s.fileInfoMap[fileName] = fileInfo
	}
	err = s.saveFileInfoMap()
	if err != nil {
		return err
	}
	return nil
}

func (s *Server) ShowFileInfoList() []FileInfo {
	var items = make([]FileInfo, 0, len(s.fileInfoMap))
	for _, v := range s.fileInfoMap {
		items = append(items, v)
	}
	//sort by last modified
	sort.Slice(items, func(i, j int) bool {
		return items[i].LastModified > items[j].LastModified
	})
	return items
}
func (s *Server) GetArchivedFileInfoList() []FileInfo {
	var items = make([]FileInfo, 0, len(s.fileInfoMap))
	for _, v := range s.fileInfoArchivedMap {
		items = append(items, v)
	}
	//sort by last modified
	sort.Slice(items, func(i, j int) bool {
		return items[i].LastModified > items[j].LastModified
	})
	return items
}

func (s *Server) QueryWordLevel(word string) (WordKnownLevel, bool) {
	// check level
	if len(word) == 0 {
		return 0, false
	}
	firstLetter := strings.ToLower(word[:1])
	if wordLevelMap, ok := s.knownWordsMap[firstLetter]; ok {
		if l, ok := wordLevelMap[word]; ok {
			return l, true
		}
	}
	return 0, false
}
func (s *Server) LevelDistribute(words []string) map[WordKnownLevel]int {
	var m = make(map[WordKnownLevel]int, 3)
	for _, text := range words {
		firstLetter := strings.ToLower(text[:1])
		if wordLevelMap, ok := s.knownWordsMap[firstLetter]; ok {
			if l, ok := wordLevelMap[text]; ok {
				m[l]++
				continue
			}
		}
		m[0]++
	}
	return m
}
func (s *Server) AllKnownWordMap() map[WordKnownLevel][]string {
	var m = make(map[WordKnownLevel][]string, 3)
	s.mux.Lock()
	defer s.mux.Unlock()
	for _, wordLevelMap := range s.knownWordsMap {
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
func (s *Server) TodayKnownWordMap() map[WordKnownLevel][]string {
	var m = make(map[WordKnownLevel][]string, 3)
	s.mux.Lock()
	defer s.mux.Unlock()
	today := time.Now().Format("2006-01-02")
	knownWordsMap := s.chartDateLevelCountMap[today]
	for level, wordLevelMap := range knownWordsMap {
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

func (s *Server) ArticleFromGobFile(fileName string) (*artical.Article, error) {
	return s.articleFromGobFile(fileName)
}

func (s *Server) articleFromGobFile(fileName string) (*artical.Article, error) {
	path := filepath.Join(s.rootDataDir, dataDir, gobFileDir, fileName)
	b, err := os.ReadFile(path)
	if err != nil {
		_ = s.deleteGobFile(fileName)
		return nil, err
	}
	return s.articleFromGobGZContent(b)
}
func (s *Server) articleFromGobGZContent(b []byte) (*artical.Article, error) {
	gzReader, err := gzip.NewReader(bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	defer gzReader.Close()
	var buf bytes.Buffer
	_, err = io.Copy(&buf, gzReader)
	if err != nil {
		return nil, err
	}
	var art artical.Article
	//gob unmarshal
	err = gob.NewDecoder(bytes.NewReader(buf.Bytes())).Decode(&art)
	if err != nil {
		return nil, err
	}
	return &art, nil
}

// DeleteGobFile delete gob file and update fileInfoMap
func (s *Server) DeleteGobFile(fileName string) error {
	return s.deleteGobFile(fileName)
}
func (s *Server) deleteGobFile(fileName string) error {
	var err error
	delete(s.fileInfoMap, fileName)
	delete(s.fileInfoArchivedMap, fileName)

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
func (s *Server) ArchiveGobFile(fileName string) error {
	info, ok := s.fileInfoMap[fileName]
	if !ok {
		return nil
	}
	delete(s.fileInfoMap, fileName)
	info.LastModified = time.Now().UnixMilli()
	s.fileInfoArchivedMap[fileName] = info
	if err := s.saveFileInfoMap(); err != nil {
		return err
	}
	return nil
}

// UnArchiveGobFile UnArchive the gob file
func (s *Server) UnArchiveGobFile(fileName string) error {
	info, ok := s.fileInfoArchivedMap[fileName]
	if !ok {
		return nil
	}
	delete(s.fileInfoArchivedMap, fileName)
	info.LastModified = time.Now().UnixMilli()
	s.fileInfoMap[fileName] = info
	if err := s.saveFileInfoMap(); err != nil {
		return err
	}
	return nil
}

// saveFileInfo .
func (s *Server) saveFileInfoMap() error {
	for name := range s.fileInfoArchivedMap {
		if _, ok := s.fileInfoMap[name]; ok {
			delete(s.fileInfoMap, name)
		}
	}
	path := filepath.Join(s.rootDataDir, dataDir, fileInfoFile)
	b, _ := json.MarshalIndent(s.fileInfoMap, "", "  ")
	err := os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
	path = filepath.Join(s.rootDataDir, dataDir, fileInfosArchived)
	b, _ = json.MarshalIndent(s.fileInfoArchivedMap, "", "  ")
	err = os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
	return nil
}

// saveFileInfo .
func (s *Server) saveChartDataFile() error {
	path := filepath.Join(s.rootDataDir, dataDir, chartDataJsonFile)
	b, _ := json.MarshalIndent(s.chartDateLevelCountMap, "", "  ")
	err := os.WriteFile(path, b, 0644)
	if err != nil {
		return err
	}
	return nil
}
