package dict

import (
	"archive/zip"
	"bytes"
	"encoding/base64"
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
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"sync"
	"time"
)

type DictZip struct {
	zipFile            string
	zipFileMap         map[string]*zip.File
	allWordHtmlFileMap map[string]string // word:htmlPath htmlPath不带html后缀
	lis                net.Listener
	port               int
	zipReadCloser      *zip.ReadCloser
	// 新增
	jsCssCache sync.Map // key:htmlBasePath, value:htmlContent string:[]byte
}

func (d *DictZip) getZipFile(path string) (*zip.File, bool) {
	path = filepath.ToSlash(path)
	// windows系统的路径分隔符是\
	f, ok := d.zipFileMap[path]
	return f, ok
}
func getAllWordHtmlFileMap(file *zip.File) (map[string]string, error) {
	r, err := file.Open()
	if err != nil {
		return nil, err
	}
	defer r.Close()
	b, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}

	allWordHtmlFileMap := make(map[string]string)
	if len(b) == 0 {
		return allWordHtmlFileMap, nil
	}
	err = json.Unmarshal(b, &allWordHtmlFileMap)
	if err != nil {
		return nil, err
	}
	return allWordHtmlFileMap, nil

}
func NewDictZip(zipFile string) (*DictZip, error) {
	z, err := zip.OpenReader(zipFile)
	if err != nil {
		return nil, err
	}
	var allWordHtmlFileMap map[string]string
	zipFileMap := make(map[string]*zip.File)
	for _, file := range z.File {
		name := filepath.ToSlash(file.Name)
		if strings.HasPrefix(name, "html") {

		}
		zipFileMap[name] = file
		if name == wordHtmlMapJsonName {
			allWordHtmlFileMap, err = getAllWordHtmlFileMap(file)
			if err != nil {
				return nil, err
			}
		}
	}
	if len(allWordHtmlFileMap) == 0 {
		return nil, fmt.Errorf("file empty: %s", wordHtmlMapJsonName)
	}
	return &DictZip{
		zipFile:            zipFile,
		zipFileMap:         zipFileMap,
		allWordHtmlFileMap: allWordHtmlFileMap,
		lis:                nil,
		port:               0,
		zipReadCloser:      z,
	}, nil
}
func (d *DictZip) FinalHtmlBasePathWithOutHtml(word string) (string, bool) {
	return d.finalHtmlBasePathWithOutHtml(word)
}
func (d *DictZip) finalHtmlBasePathWithOutHtml(word string) (string, bool) {
	p, ok := d.allWordHtmlFileMap[word]
	if !ok {
		p, ok = d.allWordHtmlFileMap[strings.ToLower(word)]
	}
	return p, ok
}

func (d *DictZip) Close() {
	d.zipFileMap = nil
	d.allWordHtmlFileMap = nil
	if lis := d.lis; lis != nil {
		lis.Close()
	}
	if z := d.zipReadCloser; z != nil {
		z.Close()
	}
	runtime.GC()
}
func (d *DictZip) start() error {
	mux := http.NewServeMux()
	mux.HandleFunc("/", d.serverHTTPIndex)
	mux.HandleFunc("/_sound/", d.serveSound)
	mux.HandleFunc("/_entry/", d.serveEntry)
	srv := &http.Server{Addr: ":0", Handler: mux}
	lis, err := net.Listen("tcp", ":0")
	if err != nil {
		return err
	}
	tcpAddr, err := net.ResolveTCPAddr("tcp", lis.Addr().String())
	if err != nil {
		return err
	}
	d.lis = lis
	d.port = tcpAddr.Port
	return srv.Serve(lis)
}

func (d *DictZip) originalContentByBasePath(basePath string) (result []byte, err error) {
	var path string
	if strings.HasSuffix(basePath, ".html") {
		path = filepath.Join(htmlDir, basePath)
	} else if strings.HasSuffix(basePath, ".css") || strings.HasSuffix(basePath, ".js") {
		path = basePath
		_, ok := d.getZipFile(path)
		if !ok {
			// js and css file can be in dictAssetDataDir
			path = filepath.Join(dictAssetDataDir, basePath)
		}
		b, ok := d.jsCssCache.Load(path)
		if ok {
			return b.([]byte), nil
		}
		defer func() {
			if err != nil {
				return
			}
			// save to cache
			d.jsCssCache.Store(path, result)
		}()
	} else {
		path = filepath.Join(dictAssetDataDir, basePath)
	}
	f, ok := d.getZipFile(path)
	if !ok {
		return nil, DataNotFound
	}
	r, err := f.Open()
	if err != nil {
		return nil, err
	}
	defer r.Close()
	b, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}

	return b, nil
}

func (d *DictZip) replaceCSS(htmlNode *html.Node, allCssNames []string) {
	styleNode := htmlquery.FindOne(htmlNode, "//style")

	if styleNode == nil {
		return
	}
	for _, cssName := range allCssNames {
		//thumb_fruit_misc.png
		mp3Href := strings.TrimSpace(cssName)
		b, err := d.originalContentByBasePath(mp3Href)
		if err != nil {
			continue
		}
		// append child node script to header, content is b
		cssNode := &html.Node{
			Data: string(b),
			Type: html.TextNode,
		}
		styleNode.AppendChild(cssNode)
		// set png href with base64
	}
}
func (d *DictZip) replaceJS(htmlNode *html.Node) {
	headNode := htmlquery.FindOne(htmlNode, "//body")
	if headNode == nil {
		return
	}
	jss := htmlquery.Find(htmlNode, "//script[contains(@src,'.js')]")
	for _, mp3 := range jss {
		mp3.Parent.RemoveChild(mp3)
		for i := 0; i < len(mp3.Attr); i++ {
			if mp3.Attr[i].Key == "src" {
				//thumb_fruit_misc.png
				mp3Href := strings.TrimSpace(mp3.Attr[i].Val)
				b, err := d.originalContentByBasePath(mp3Href)
				if err != nil {
					continue
				}
				// append child node script to header, content is b
				scriptNode := html.Node{
					Type: html.ElementNode,
					Data: "script",
					FirstChild: &html.Node{
						Data: string(b),
						Type: html.TextNode,
					},
				}
				headNode.AppendChild(&scriptNode)
				// set png href with base64
			}
		}
	}
}
func (d *DictZip) replaceMP3(htmlNode *html.Node) {
	headNode := htmlquery.FindOne(htmlNode, "//head")
	if headNode == nil {
		return
	}
	mp3s := htmlquery.Find(htmlNode, "//a[contains(@href,'.mp3')]")
	for _, mp3 := range mp3s {
		for i := 0; i < len(mp3.Attr); i++ {
			if mp3.Attr[i].Key == "href" {
				//sound://apple__gb_5.mp3
				mp3Href := strings.TrimPrefix(strings.TrimSpace(mp3.Attr[i].Val), "sound://")
				b, err := d.originalContentByBasePath(mp3Href)
				if err != nil {
					mylog.Error(err.Error())
					continue
				}
				// x-wav可以播放
				src := fmt.Sprintf("data:audio/x-wav;base64,%s", base64.StdEncoding.EncodeToString(b))

				// set mp3 href with base64

				// remove href
				mp3.Attr[i].Key = "onclick"
				onclick := fmt.Sprintf(`(function () { var audio = new Audio(); audio.src = "%s"; audio.play(); })()`, src)
				mp3.Attr[i].Val = onclick
				//mp3.Data = "a"
				//scriptNode := &html.Node{
				//	Type: html.ElementNode,
				//	Data: "script",
				//	FirstChild: &html.Node{
				//		Data: fmt.Sprintf(`function audio%d() { var audio = new Audio(); audio.src = "%s"; audio.play(); }`, idx, val),
				//		Type: html.TextNode,
				//	},
				//}
				//headNode.AppendChild(scriptNode)
			}
		}
	}
}
func (d *DictZip) replacePng(htmlNode *html.Node) {
	pngs := htmlquery.Find(htmlNode, "//img[contains(@src,'.png')]")
	for _, mp3 := range pngs {
		for i := 0; i < len(mp3.Attr); i++ {
			if mp3.Attr[i].Key == "src" {
				//thumb_fruit_misc.png
				mp3Href := strings.TrimSpace(mp3.Attr[i].Val)
				b, err := d.originalContentByBasePath(mp3Href)
				if err != nil {
					mylog.Error(err.Error())
					continue
				}
				// set png href with base64
				mp3.Attr[i].Val = fmt.Sprintf("data:image/png;base64,%s", base64.StdEncoding.EncodeToString(b))
			}
		}
	}
}
func (d *DictZip) replaceCss(htmlNode *html.Node) {
	styleNode := htmlquery.FindOne(htmlNode, "//style")
	if styleNode == nil {
		return
	}
	pngs := htmlquery.Find(htmlNode, "//link[contains(@href,'.css')]")
	for _, mp3 := range pngs {
		mp3.Parent.RemoveChild(mp3)
		for i := 0; i < len(mp3.Attr); i++ {
			if mp3.Attr[i].Key == "href" {
				//thumb_fruit_misc.png
				cssName := strings.TrimSpace(mp3.Attr[i].Val)
				b, err := d.originalContentByBasePath(cssName)
				if err != nil {
					continue
				}
				// append child node script to header, content is b
				cssNode := &html.Node{
					Data: string(b),
					Type: html.TextNode,
				}
				styleNode.AppendChild(cssNode)
			}
		}
	}
}
func (d *DictZip) replaceHTMLContent(htmlContent string) (string, error) {
	// 查找正则表达式去除所有的含有css的标签, 因为过滤后的文本的link标签可能在body中，所以需要用htmlquery来解析
	cssExpr := `<link.*?href="(.*\.css)".*?>`
	reg := regexp.MustCompile(cssExpr)
	var allCssNames []string
	csss := reg.FindAllStringSubmatch(htmlContent, -1)
	for _, cs := range csss {
		allCssNames = append(allCssNames, cs[1])
	}
	htmlContent = reg.ReplaceAllString(htmlContent, "")
	htmlNode, err := htmlquery.Parse(strings.NewReader(htmlContent))
	if err != nil {
		return htmlContent, nil
	}

	headNode := htmlquery.FindOne(htmlNode, "//head")
	if headNode == nil {
		return "", errors.New("head node not found")
	}
	bodyNode := htmlquery.FindOne(htmlNode, "//body")
	if bodyNode == nil {
		return "", errors.New("body node not found")
	}
	styleNode := htmlquery.FindOne(htmlNode, "//style")
	if styleNode == nil {
		return "", errors.New("style node not found")
	}
	// 替换的顺序不能变，因为替换后的htmlNode会变化 ，比如替换了png后，会添加script标签
	d.replacePng(htmlNode)
	d.replaceJS(htmlNode)
	d.replaceMP3(htmlNode)
	d.replaceCSS(htmlNode, allCssNames)
	// 找出包含所有的script标签并且src属性值包含.js的标签，然后删除这些标签
	// 找出包含所有的link标签并且href属性值包含.css的标签，然后删除这些标签
	// 找出所有的 <a> 元素且链接值包含.mp3的标签
	//htmlNode, _ = html.Parse(bytes.NewReader([]byte(htmlquery.OutputHTML(htmlNode, true))))
	//htmlNode, _ = html.Parse(bytes.NewReader([]byte(htmlquery.OutputHTML(htmlNode, true))))
	//htmlNode, _ = html.Parse(bytes.NewReader([]byte(htmlquery.OutputHTML(htmlNode, true))))
	// 找出所有的 src 属性值包含.png的标签 ,一定要先替换Png，再替换mp3，否则会找不到png,因为mp3中会添加script标签
	//htmlNode, _ = html.Parse(bytes.NewReader([]byte(htmlquery.OutputHTML(htmlNode, true))))
	return htmlquery.OutputHTML(htmlNode, true), nil
}

func (d *DictZip) GetHTMLRenderContentByWord(word string) (string, error) {
	basePath, ok := d.finalHtmlBasePathWithOutHtml(word)
	if !ok {
		return "", DataNotFound
	}
	content, err := d.originalContentByBasePath(basePath + ".html")
	if err != nil {
		return "", err
	}
	contentStr, needReplace := completeHtml(word, string(content))
	if needReplace {
		return d.replaceHTMLContent(contentStr)
	}
	return contentStr, nil
}

func completeHtml(word, htmlOriginalContent string) (string, bool) {
	const linkPrefix = "@@@LINK="
	var needReplace = true
	if strings.HasPrefix(htmlOriginalContent, linkPrefix) {
		word := strings.TrimSpace(strings.TrimPrefix(htmlOriginalContent, linkPrefix))
		htmlOriginalContent = fmt.Sprintf(entryDiv, word, word)
		needReplace = false
	}
	complete := fmt.Sprintf(tmpl, word, htmlOriginalContent)
	return complete, needReplace
}

// htmlBasePath 带html后缀
func (d *DictZip) getContentByHtmlBasePath(word, htmlBasePath string) ([]byte, error) {
	f, ok := d.getZipFile(filepath.Join(htmlDir, htmlBasePath))
	if !ok {
		return nil, DataNotFound
	}
	fr, err := f.Open()
	if err != nil {
		return nil, err
	}
	defer fr.Close()
	b, err := io.ReadAll(fr)
	if err != nil {
		return nil, err
	}
	s := string(b)
	const linkPrefix = "@@@LINK="
	if strings.HasPrefix(s, linkPrefix) {
		word := strings.TrimSpace(strings.TrimPrefix(s, linkPrefix))
		htmlName, ok := d.FinalHtmlBasePathWithOutHtml(word)
		if ok {
			s = fmt.Sprintf(`<div>👉<a href="/%s.html?word=%s">%s</a></div>`, htmlName, url.QueryEscape(word), word)
		}
	}
	htmlContent := fmt.Sprintf(tmpl, word, s)
	// 查找所有的html图片。替换html中的图片为base64图片
	// <img src="images/1.png" alt="1.png" />
	// <img src="images/2.png" alt="2.png" />
	return []byte(htmlContent), nil
}
func (d *DictZip) addOnClickMp3(htmlNode *html.Node) {
	mp3s := htmlquery.Find(htmlNode, "//a[contains(@href,'.mp3')]")
	for _, mp3 := range mp3s {
		for i := 0; i < len(mp3.Attr); i++ {
			if mp3.Attr[i].Key == "href" {
				// x-wav可以播放
				src := fmt.Sprintf("/_sound/%s", strings.TrimPrefix(mp3.Attr[i].Val, "sound://"))
				val := fmt.Sprintf(`(function(){var audio=new Audio();audio.src='%s';audio.play();})()`, src)
				// set mp3 href with base64
				// remove href
				mp3.Attr[i].Key = "onclick"
				mp3.Attr[i].Val = val
				//mp3.Data = "a"
			}
		}
	}
}
func (d *DictZip) changeEntreHref(htmlNode *html.Node) {
	mp3s := htmlquery.Find(htmlNode, "//a[contains(@href,'entry://')]")
	for _, mp3 := range mp3s {
		for i := 0; i < len(mp3.Attr); i++ {
			if mp3.Attr[i].Key == "href" {
				// x-wav可以播放
				val := strings.ReplaceAll(mp3.Attr[i].Val, "entry://", "/_entry/")
				// set mp3 href with base64
				// remove href
				mp3.Attr[i].Val = val
			}
		}
	}
}

// baseHTMLPath with .html
func (d *DictZip) writeByWordBaseHTMLPath(w http.ResponseWriter, word, baseHTMLPath string) {
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

func (d *DictZip) serverHTTPHtml(w http.ResponseWriter, r *http.Request) {
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	word := r.URL.Query().Get("word")
	d.writeByWordBaseHTMLPath(w, word, urlPath)
}

func (d *DictZip) serverAssetsExceptHtml(w http.ResponseWriter, r *http.Request) {
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	if strings.HasSuffix(urlPath, ".js") {
		w.Header().Set("Content-Type", "text/javascript")
	} else if strings.HasSuffix(urlPath, ".css") {
		w.Header().Set("Content-Type", "text/css; charset=utf-8")
	} else {
		urlPath = filepath.Join(dictAssetDataDir, urlPath)
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

func (d *DictZip) serveSound(w http.ResponseWriter, r *http.Request) {
	// /_sound/
	name := strings.TrimPrefix(r.URL.Path, "/_sound/")
	mp3, err := d.originalContentByBasePath(name)
	if err != nil {
		w.WriteHeader(500)
		w.Write([]byte(err.Error()))
		return
	}
	http.ServeContent(w, r, name, time.Now(), bytes.NewReader(mp3))
}

func (d *DictZip) serveEntry(w http.ResponseWriter, r *http.Request) {
	// /_sound/
	word := strings.TrimPrefix(r.URL.Path, "/_entry/")
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

func (d *DictZip) serverHTTPIndex(w http.ResponseWriter, r *http.Request) {
	// html
	urlPath := strings.TrimPrefix(r.URL.Path, "/")
	mylog.Info("serverHTTPIndex", "path", r.URL.Path, "isHtml", strings.HasSuffix(urlPath, ".html"))
	if strings.HasSuffix(urlPath, ".html") {
		d.serverHTTPHtml(w, r)
		return
	}
	d.serverAssetsExceptHtml(w, r)
}
