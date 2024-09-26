package dict

import (
	"bytes"
	"errors"
	"fmt"
	"mywords/pkg/log"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// WebDict 提供web服务查询
type WebDict struct {
	oneDict *OneDict // be careful, it maybe nil if no dict set
	runPort int
}

// RunPort return the run port
// <=0 means not run, >0 means run
func (m *WebDict) RunPort() int {
	return m.runPort
}

// NewWebDict 0 runPort means a random port
func NewWebDict(oneDict *OneDict, dictPort int) (*WebDict, error) {
	m := WebDict{
		runPort: 0,
		oneDict: oneDict,
	}
	if dictPort < 0 {
		return &m, nil
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/", m.serverHTTPIndex)
	mux.HandleFunc("/_query", m.query)
	mux.HandleFunc("/_sound/", m.serveSound)
	mux.HandleFunc("/_entry/", m.serveEntry)
	addr := fmt.Sprintf(":%d", dictPort)
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
	go func() {
		err := srv.Serve(lis)
		if err != nil {
			log.Printf("web dict server error: %v", err)
		}
	}()
	log.Println("WebDict", "runPort", m.runPort)
	return &m, nil
}

func (m *WebDict) serverHTTPHtml(w http.ResponseWriter, r *http.Request) {
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	// 不同语言对于Url path编码的标准可能不同, 所以 不应该在对urlPath进行解码或编码.直接使用原声的url path
	word := r.URL.Query().Get("word")
	d := m.oneDict
	if d.zipFile == "" {
		http.Error(w, loadFailed, http.StatusInternalServerError)
		return
	}
	d.writeByWordBaseHTMLPath(w, word, urlPath)
}

// serverStartTime as the file last modify time
var serverStartTime = time.Now()

func (m *WebDict) serverAssetsExceptHtml(w http.ResponseWriter, r *http.Request) {
	d := m.oneDict
	if d.zipFile == "" {
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

func (m *WebDict) serveSound(w http.ResponseWriter, r *http.Request) {
	// /_sound/
	name := strings.TrimPrefix(r.URL.Path, "/_sound/")
	d := m.oneDict
	if d.zipFile == "" {
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

const loadFailed = "error: please select a non-default dictionary first"

func (m *WebDict) serveEntry(w http.ResponseWriter, r *http.Request) {
	// /_sound/
	word := strings.TrimPrefix(r.URL.Path, "/_entry/")

	d := m.oneDict
	if d.zipFile == "" {
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

func (m *WebDict) serverHTTPIndex(w http.ResponseWriter, r *http.Request) {
	// html
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	log.Println("serverHTTPIndex", "path", r.URL.Path, "isHtml", strings.HasSuffix(urlPath, ".html"))
	if strings.HasSuffix(urlPath, ".html") {
		m.serverHTTPHtml(w, r)
		return
	}
	m.serverAssetsExceptHtml(w, r)
}
func (m *WebDict) query(w http.ResponseWriter, r *http.Request) {
	word := r.URL.Query().Get("word")
	if word == "" {
		/// Bad Request
		http.Error(w, "word is empty", http.StatusBadRequest)
		return
	}

	d := m.oneDict
	if d.zipFile == "" {
		http.Error(w, loadFailed, http.StatusInternalServerError)
		return
	}
	htmlPath, ok := d.FinalHtmlBasePathWithOutHtml(word)
	if !ok {
		http.NotFound(w, r)
		return
	}
	d.writeByWordBaseHTMLPath(w, word, htmlPath+".html")
}

func (m *WebDict) GetUrlByWord(hostname string, word string) (string, bool) {

	runPort := m.runPort
	if runPort == 0 {
		return "", false
	}
	d := m.oneDict
	if d.zipFile == "" {
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

func (m *WebDict) FinalHtmlBasePathWithOutHtml(word string) (string, bool) {

	runPort := m.runPort
	if runPort <= 0 {
		return "", false
	}
	d := m.oneDict
	if d.zipFile == "" {
		return "", false
	}
	htmlPath, ok := d.FinalHtmlBasePathWithOutHtml(word)
	if !ok {
		return "", false
	}
	return htmlPath, true
}
