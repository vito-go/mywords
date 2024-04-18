package dict

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	htmlquery "github.com/antchfx/xquery/html"
	"golang.org/x/net/html"
	"io"
	"mywords/mylog"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"time"
)

// MultiDict 管理多个Dict
type MultiDict struct {
	rootDataDir   string                   //app data dir
	dictIndexInfo dictIndexInfo            //  dictIndexInfo
	oneDict       *atomic.Pointer[OneDict] // be careful, it maybe nil if no dict set
	runPort       int
}

func (m *MultiDict) saveInfo() error {

	b, _ := json.MarshalIndent(m.dictIndexInfo, "", "  ")
	err := os.WriteFile(filepath.Join(m.rootDataDir, appDictDir, dictInfoJson), b, 0644)
	return err
}

type basePathTitleMap map[string]string

func (b basePathTitleMap) copy() basePathTitleMap {
	var resultMap = make(basePathTitleMap)
	for k, v := range b {
		resultMap[k] = v
	}
	return resultMap
}

type dictIndexInfo struct {
	DefaultDictBasePath  string           `json:"defaultDictBasePath,omitempty"`
	DictBasePathTitleMap basePathTitleMap `json:"dictBasePathTitleMap,omitempty"` //zipFile:name, do not modify directly, please copy it first when modifing
}

func (d dictIndexInfo) Copy() dictIndexInfo {
	return dictIndexInfo{
		DefaultDictBasePath:  d.DefaultDictBasePath,
		DictBasePathTitleMap: d.DictBasePathTitleMap.copy(),
	}
}

// baseHTMLPath with .html
func (d *OneDict) writeByWordBaseHTMLPath(w http.ResponseWriter, word, baseHTMLPath string) {
	content, err := d.getContentByHtmlBasePath(word, baseHTMLPath)
	if err != nil {
		if errors.Is(err, DataNotFound) {
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	//content = bytes.ReplaceAll(content, []byte("entry://"), []byte("/_entry/"))
	htmlNode, err := htmlquery.Parse(bytes.NewReader(content))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	d.replaceSoundWithSourceURL(htmlNode)
	d.changeEntryHref(htmlNode)
	html.Render(w, htmlNode)
	return
}

func (m *MultiDict) serverHTTPHtml(w http.ResponseWriter, r *http.Request) {
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	// 不同语言对于Url path编码的标准可能不同, 所以 不应该在对urlPath进行解码或编码.直接使用原声的url path
	word := r.URL.Query().Get("word")
	d := m.oneDict.Load()
	if d == nil {
		http.Error(w, loadFailed, http.StatusInternalServerError)
		return
	}
	d.writeByWordBaseHTMLPath(w, word, urlPath)
}

// serverStartTime as the file last modify time
var serverStartTime = time.Now()

func (m *MultiDict) serverAssetsExceptHtml(w http.ResponseWriter, r *http.Request) {
	d := m.oneDict.Load()
	if d == nil {
		http.Error(w, loadFailed, http.StatusInternalServerError)
		return
	}
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	b, err := d.originalContentByBasePath(urlPath)
	if err != nil {
		if errors.Is(err, DataNotFound) {
			http.NotFound(w, r)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if strings.HasSuffix(urlPath, ".js") {
		w.Header().Set("Content-Type", "text/javascript")
	} else if strings.HasSuffix(urlPath, ".css") {
		w.Header().Set("Content-Type", "text/css; charset=utf-8")
	} else if strings.HasSuffix(urlPath, ".spx") {
		// TODO
		// Uncaught (in promise) DOMException: Failed to load because no supported source was found.
		// HTML标准和大多数现代浏览器通常不支持SPX（Speex）格式的音频文件。
		//浏览器的音频解码器通常支持的格式包括MP3, WAV, AAC, Ogg Vorbis, Ogg Opus, 和WebM等。

		//w.Header().Set("Content-Type", "audio/x-speex")
	}
	http.ServeContent(w, r, urlPath, serverStartTime, bytes.NewReader(b))
}

func (m *MultiDict) serveSound(w http.ResponseWriter, r *http.Request) {
	// /_sound/
	name := strings.TrimPrefix(r.URL.Path, "/_sound/")
	d := m.oneDict.Load()
	if d == nil {
		http.Error(w, loadFailed, http.StatusInternalServerError)
		return
	}
	mp3, err := d.originalContentByBasePath(name)
	if err != nil {
		if errors.Is(err, DataNotFound) {
			http.NotFound(w, r)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.ServeContent(w, r, name, serverStartTime, bytes.NewReader(mp3))
}

const loadFailed = "dict loaded failed"

func (m *MultiDict) serveEntry(w http.ResponseWriter, r *http.Request) {
	// /_sound/
	word := strings.TrimPrefix(r.URL.Path, "/_entry/")

	d := m.oneDict.Load()
	if d == nil {
		http.Error(w, loadFailed, http.StatusInternalServerError)
		return
	}
	basePath, ok := d.finalHtmlBasePathWithOutHtml(word)
	if !ok {
		http.NotFound(w, r)
		return
	}
	// 还是得跳转，否则由于二级路径无法加载js和ｃｓｓ文件
	u := fmt.Sprintf("/%s.html", basePath)
	http.Redirect(w, r, u, http.StatusMovedPermanently)
}

func (m *MultiDict) serverHTTPIndex(w http.ResponseWriter, r *http.Request) {
	// html
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	mylog.Info("serverHTTPIndex", "path", r.URL.Path, "isHtml", strings.HasSuffix(urlPath, ".html"))
	if strings.HasSuffix(urlPath, ".html") {
		m.serverHTTPHtml(w, r)
		return
	}
	m.serverAssetsExceptHtml(w, r)
}

// NewMultiDictZip 0 runPort means a random port
func NewMultiDictZip(rootDir string, runPort int) (*MultiDict, error) {
	rootDir = filepath.ToSlash(rootDir)
	err := os.MkdirAll(filepath.Join(rootDir, appDictDir), 0755)
	if err != nil {
		return nil, err
	}
	var info dictIndexInfo
	info.DictBasePathTitleMap = make(map[string]string)
	b, err := os.ReadFile(filepath.Join(rootDir, appDictDir, dictInfoJson))
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	if len(b) > 0 {
		if err = json.Unmarshal(b, &info); err != nil {
			return nil, err
		}
	}
	DictZipAtomic := new(atomic.Pointer[OneDict])
	var dictIndexInfoAtomic = new(atomic.Value)
	dictIndexInfoAtomic.Store(info)
	m := MultiDict{
		rootDataDir:   rootDir,
		runPort:       runPort,
		oneDict:       DictZipAtomic,
		dictIndexInfo: info,
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/", m.serverHTTPIndex)
	mux.HandleFunc("/_sound/", m.serveSound)
	mux.HandleFunc("/_entry/", m.serveEntry)
	addr := fmt.Sprintf(":%d", runPort)
	srv := &http.Server{Addr: addr, Handler: mux}
	lis, err := net.Listen("tcp", addr)
	if err != nil {
		return nil, err
	}
	tcpAddr, err := net.ResolveTCPAddr("tcp", lis.Addr().String())
	if err != nil {
		return nil, err
	}
	m.runPort = tcpAddr.Port
	go srv.Serve(lis)
	if info.DefaultDictBasePath != "" {
		go m.SetDefaultDict(info.DefaultDictBasePath)
	}
	return &m, nil
}

func (m *MultiDict) GetDefaultDict() string {
	return m.dictIndexInfo.DefaultDictBasePath
}
func (m *MultiDict) GetHTMLRenderContentByWord(word string) (string, error) {
	d := m.oneDict.Load()
	if d == nil {
		return "", nil
	}
	return d.GetHTMLRenderContentByWord(word)

}
func (m *MultiDict) GetUrlByWord(hostname string, word string) (string, bool) {

	runPort := m.runPort
	if runPort == 0 {
		return "", false
	}
	d := m.oneDict.Load()
	if d == nil {
		return "", false
	}
	htmlPath, ok := d.FinalHtmlBasePathWithOutHtml(word)
	if !ok {
		return "", false
	}
	if hostname == "" {
		hostname = "localhost"
	}
	u := fmt.Sprintf("http://%s:%d/%s.html?word=%s", hostname, m.runPort, htmlPath, url.QueryEscape(word))
	return u, true
}

func (m *MultiDict) FinalHtmlBasePathWithOutHtml(word string) (string, bool) {

	runPort := m.runPort
	if runPort == 0 {
		return "", false
	}
	d := m.oneDict.Load()
	if d == nil {
		return "", false
	}
	htmlPath, ok := d.FinalHtmlBasePathWithOutHtml(word)
	if !ok {
		return "", false
	}
	return htmlPath, true
}

func (m *MultiDict) DictBasePathTitleMap() map[string]string {

	DictBasePathTitleMap := m.dictIndexInfo.DictBasePathTitleMap
	result := make(map[string]string, len(DictBasePathTitleMap))
	for k, v := range DictBasePathTitleMap {
		result[k] = v
	}
	return result
}
func (m *MultiDict) UpdateDictName(basePath, title string) error {

	DictBasePathTitleMap := m.dictIndexInfo.DictBasePathTitleMap
	_, ok := DictBasePathTitleMap[basePath]
	if !ok {
		return errors.New("字典不存在")
	}
	DictBasePathTitleMap[basePath] = title
	if err := m.saveInfo(); err != nil {
		return err
	}
	return nil
}
func (m *MultiDict) SetDefaultDict(basePath string) error {

	return m.setDefaultDict(basePath)
}
func (m *MultiDict) setDefaultDict(basePath string) error {
	if basePath == "" {
		if d := m.oneDict.Load(); d != nil {
			d.Close()
		}
		copyInfo := m.dictIndexInfo.Copy()
		copyInfo.DefaultDictBasePath = basePath
		m.dictIndexInfo = copyInfo
		m.oneDict.Store(nil)
		if err := m.saveInfo(); err != nil {
			return err
		}
		return nil
	}
	oldDict := m.oneDict.Load()
	if m.dictIndexInfo.DefaultDictBasePath == basePath && oldDict != nil {
		return nil
	}
	zipFile := filepath.Join(m.rootDataDir, appDictDir, basePath)
	newDict, err := NewDictZip(zipFile)
	if err != nil {
		return err
	}
	if oldDict != nil {
		oldDict.Close()
	}
	copyInfo := m.dictIndexInfo.Copy()
	copyInfo.DefaultDictBasePath = basePath
	m.dictIndexInfo = copyInfo
	m.oneDict.Store(newDict)
	if err = m.saveInfo(); err != nil {
		return err
	}
	return nil
}
func (m *MultiDict) DelDict(basePath string) error {

	if basePath == "" {
		return nil
	}
	if basePath == m.dictIndexInfo.DefaultDictBasePath {
		m.dictIndexInfo.DefaultDictBasePath = ""

		m.oneDict.Load().Close()
	}
	delete(m.dictIndexInfo.DictBasePathTitleMap, basePath)
	if err := m.saveInfo(); err != nil {
		return err
	}
	os.Remove(filepath.Join(m.rootDataDir, appDictDir, basePath))
	return nil
}
func (m *MultiDict) AddDict(originalZipPath string) error {
	dictBasePath := filepath.Base(originalZipPath)
	_, ok := m.dictIndexInfo.DictBasePathTitleMap[dictBasePath]
	if ok {
		return fmt.Errorf("该字典已加载: %s, 请修改文件名或者删除旧词典", dictBasePath)
	}
	d, err := NewDictZip(originalZipPath)
	if err != nil {
		return err
	}
	d.Close()
	zipFile := filepath.Join(m.rootDataDir, appDictDir, dictBasePath)
	err = copyFile(zipFile, originalZipPath)
	if err != nil {
		return err
	}
	basePath := filepath.Base(zipFile)
	copyInfo := m.dictIndexInfo.Copy()
	copyInfo.DictBasePathTitleMap[basePath] = basePath
	m.dictIndexInfo = copyInfo
	if err = m.saveInfo(); err != nil {
		return err
	}
	if len(m.dictIndexInfo.DictBasePathTitleMap) == 1 {
		return m.setDefaultDict(basePath)
	}
	return err
}
func (m *MultiDict) SearchByKeyWord(keyWord string) []string {

	d := m.oneDict.Load()
	if d == nil {
		return nil
	}
	return SearchByKeyWord(keyWord, d.allWordHtmlFileMap)
}

func copyFile(tar, src string) error {
	fw, err := os.Create(tar)
	if err != nil {
		return err
	}
	defer fw.Close()
	fr, err := os.Open(src)
	if err != nil {
		os.Remove(tar)
		return err
	}
	defer fr.Close()
	_, err = io.Copy(fw, fr)
	if err != nil {
		return err
	}
	return nil
}
