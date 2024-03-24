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
	"sync"
	"sync/atomic"
	"time"
)

// MultiDict 管理多个Dict
type MultiDict struct {
	mux           sync.Mutex
	rootDataDir   string                   //app data dir
	dictIndexInfo dictIndexInfo            //  dictIndexInfo
	oneDict       *atomic.Pointer[OneDict] // be careful, it maybe nil if no dict set
	runPort       int
	host          string //default localhost
	onceInit      sync.Once
}

func (m *MultiDict) saveInfo() error {
	b, _ := json.MarshalIndent(m.dictIndexInfo, "", "  ")
	err := os.WriteFile(filepath.Join(m.rootDataDir, appDictDir, dictInfoJson), b, 0644)
	return err
}

type dictIndexInfo struct {
	DefaultDictBasePath  string            `json:"defaultDictBasePath,omitempty"`
	DictBasePathTitleMap map[string]string `json:"dictBasePathTitleMap,omitempty"` //zipFile:name
}

// baseHTMLPath with .html
func (d *OneDict) writeByWordBaseHTMLPath(w http.ResponseWriter, word, baseHTMLPath string) {
	content, err := d.getContentByHtmlBasePath(word, baseHTMLPath)
	if err != nil {
		if errors.Is(err, DataNotFound) {
			http.Error(w, "404 page not found", http.StatusNotFound)
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
	d.addOnClickMp3(htmlNode)
	d.changeEntreHref(htmlNode)
	html.Render(w, htmlNode)
	return
}

func (m *MultiDict) serverHTTPHtml(w http.ResponseWriter, r *http.Request) {
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	word := r.URL.Query().Get("word")
	d := m.oneDict.Load()
	if d == nil {
		return
	}
	d.writeByWordBaseHTMLPath(w, word, urlPath)
}

func (m *MultiDict) serverAssetsExceptHtml(w http.ResponseWriter, r *http.Request) {
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	if strings.HasSuffix(urlPath, ".js") {
		w.Header().Set("Content-Type", "text/javascript")
	} else if strings.HasSuffix(urlPath, ".css") {
		w.Header().Set("Content-Type", "text/css; charset=utf-8")
	} else {
		urlPath = filepath.Join(dictAssetDataDir, urlPath)
	}
	d := m.oneDict.Load()
	if d == nil {
		return
	}
	f, ok := d.getZipFile(urlPath)
	if !ok {
		http.NotFound(w, r)
		return
	}
	fr, err := f.Open()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer fr.Close()

	b, err := io.ReadAll(fr)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.ServeContent(w, r, f.Name, f.Modified, bytes.NewReader(b))
}

func (m *MultiDict) serveSound(w http.ResponseWriter, r *http.Request) {
	// /_sound/
	name := strings.TrimPrefix(r.URL.Path, "/_sound/")
	d := m.oneDict.Load()
	if d == nil {
		return
	}
	mp3, err := d.originalContentByBasePath(name)
	if err != nil {
		w.WriteHeader(500)
		w.Write([]byte(err.Error()))
		return
	}
	http.ServeContent(w, r, name, time.Now(), bytes.NewReader(mp3))
}

func (m *MultiDict) serveEntry(w http.ResponseWriter, r *http.Request) {
	// /_sound/
	word := strings.TrimPrefix(r.URL.Path, "/_entry/")

	d := m.oneDict.Load()
	if d == nil {
		return
	}
	basePath, ok := d.finalHtmlBasePathWithOutHtml(word)
	if !ok {
		http.NotFound(w, r)
		return
	}
	//d.writeByWordBaseHTMLPath(w, basePath+".html")
	//return
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

// NewMultiDictZip  runPort 0 means a random port
func NewMultiDictZip(rootDir string, host string, runPort int) (*MultiDict, error) {
	rootDir = filepath.ToSlash(rootDir)

	err := os.MkdirAll(filepath.Join(rootDir, appDictDir), 0755)
	if err != nil {
		return nil, err
	}
	var info dictIndexInfo
	b, err := os.ReadFile(filepath.Join(rootDir, appDictDir, dictInfoJson))
	if err != nil {
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
	if host == "" {
		host = "127.0.0.1"
	}
	m := MultiDict{
		mux:           sync.Mutex{},
		host:          host,
		rootDataDir:   rootDir,
		runPort:       runPort,
		onceInit:      sync.Once{},
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
func (m *MultiDict) GetUrlByWord(word string) (string, bool) {
	m.mux.Lock()
	defer m.mux.Unlock()
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
	u := fmt.Sprintf("http://%s:%d/%s.html?word=%s", m.host, m.runPort, htmlPath, url.QueryEscape(word))
	return u, true
}

func (m *MultiDict) FinalHtmlBasePathWithOutHtml(word string) (string, bool) {
	m.mux.Lock()
	defer m.mux.Unlock()
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
	m.mux.Lock()
	defer m.mux.Unlock()
	DictBasePathTitleMap := m.dictIndexInfo.DictBasePathTitleMap
	result := make(map[string]string, len(DictBasePathTitleMap))
	for k, v := range DictBasePathTitleMap {
		result[k] = v
	}
	return result
}
func (m *MultiDict) UpdateDictName(basePath, title string) error {
	m.mux.Lock()
	defer m.mux.Unlock()
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
	m.mux.Lock()
	defer m.mux.Unlock()
	return m.setDefaultDict(basePath)
}
func (m *MultiDict) setDefaultDict(basePath string) error {

	if basePath == "" {
		if d := m.oneDict.Load(); d != nil {
			d.Close()
		}
		m.dictIndexInfo.DefaultDictBasePath = basePath
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
	m.dictIndexInfo.DefaultDictBasePath = basePath
	m.oneDict.Store(newDict)
	if err = m.saveInfo(); err != nil {
		return err
	}
	return nil
}
func (m *MultiDict) DelDict(basePath string) error {
	m.mux.Lock()
	defer m.mux.Unlock()
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
	m.mux.Lock()
	defer m.mux.Unlock()
	dictBasePath := filepath.Base(originalZipPath)
	_, ok := m.dictIndexInfo.DictBasePathTitleMap[dictBasePath]
	if ok {
		return fmt.Errorf("该字典已加载: %s", dictBasePath)
	}
	zipFile := filepath.Join(m.rootDataDir, appDictDir, dictBasePath)
	err := copyFile(zipFile, originalZipPath)
	if err != nil {
		return err
	}
	basePath := filepath.Base(zipFile)
	m.dictIndexInfo.DictBasePathTitleMap[basePath] = basePath
	if err = m.saveInfo(); err != nil {
		return err
	}
	if len(m.dictIndexInfo.DictBasePathTitleMap) == 1 {
		return m.setDefaultDict(basePath)
	}
	return err
}
func (m *MultiDict) SearchByKeyWord(keyWord string) []string {
	m.mux.Lock()
	defer m.mux.Unlock()
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
