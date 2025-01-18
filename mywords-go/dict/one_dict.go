package dict

import (
	"archive/zip"
	"bytes"
	_ "embed"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	htmlquery "github.com/antchfx/xquery/html"
	"golang.org/x/net/html"
	"io"
	"mywords/pkg/log"
	"net/http"
	"net/url"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"sync"
)

type OneDict struct {
	mux     sync.RWMutex
	zipFile string // empty string means use default dict
	dictId  int64

	zipFileMap         map[string]*zip.File
	allWordHtmlFileMap map[string]string // word:htmlPath htmlPath不带html后缀
	zipReadCloser      *zip.ReadCloser
	jsCssCache         sync.Map // deprecated:  key:htmlBasePath, value:htmlContent string:[]byte
	defaultDictWordMap map[string]string
}

func (d *OneDict) getZipFile(path string) (*zip.File, bool) {
	path = filepath.ToSlash(path)
	// windows 系统的路径分隔符是\
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

func (d *OneDict) DefaultWordMeaning(word string) (string, bool) {
	data, ok := d.defaultDictWordMap[word]
	return data, ok
}
func NewOneDict() *OneDict {
	return &OneDict{
		mux:                sync.RWMutex{},
		zipFile:            "",
		zipFileMap:         nil,
		allWordHtmlFileMap: nil,
		zipReadCloser:      nil,
		jsCssCache:         sync.Map{},
		defaultDictWordMap: DefaultDictWordMap,
	}
}
func (d *OneDict) SetDict(zipFile string) error {
	d.mux.Lock()
	defer d.mux.Unlock()
	z, err := zip.OpenReader(zipFile)
	if err != nil {
		return err
	}
	var allWordHtmlFileMap map[string]string
	zipFileMap := make(map[string]*zip.File)
	for _, file := range z.File {
		name := filepath.ToSlash(file.Name)
		zipFileMap[name] = file
		if name == wordHtmlMapJsonName {
			allWordHtmlFileMap, err = getAllWordHtmlFileMap(file)
			if err != nil {
				_ = z.Close()
				return err
			}
		}
	}
	if len(allWordHtmlFileMap) == 0 {
		_ = z.Close()
		return fmt.Errorf("字典文件中没有找到 %s", wordHtmlMapJsonName)
	}
	d.Close()
	d.zipFile = zipFile
	d.zipFileMap = zipFileMap
	d.allWordHtmlFileMap = allWordHtmlFileMap
	d.zipReadCloser = z
	return nil
}

func (d *OneDict) FinalHtmlBasePathWithOutHtml(word string) (string, bool) {
	return d.finalHtmlBasePathWithOutHtml(word)
}
func (d *OneDict) finalHtmlBasePathWithOutHtml(word string) (string, bool) {
	p, ok := d.allWordHtmlFileMap[word]
	if !ok {
		p, ok = d.allWordHtmlFileMap[strings.ToLower(word)]
	}
	return p, ok
}

func (d *OneDict) Close() {
	d.zipFileMap = nil
	d.zipFile = ""
	d.allWordHtmlFileMap = nil
	if z := d.zipReadCloser; z != nil {
		z.Close()
	}
	runtime.GC()
}

func (d *OneDict) originalContentByBasePath(basePath string) (result []byte, err error) {
	var path string
	if strings.HasSuffix(basePath, ".html") {
		path = filepath.Join(htmlDir, basePath)
	} else if strings.HasSuffix(basePath, ".css") || strings.HasSuffix(basePath, ".js") {
		path = basePath
		if _, ok := d.getZipFile(path); !ok {
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
		if _, ok := d.getZipFile(path); !ok {
			path = basePath
		}
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

func (d *OneDict) replaceCSS(htmlNode *html.Node, allCssNames []string) {
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
func (d *OneDict) replaceJS(htmlNode *html.Node) {
	headNode := htmlquery.FindOne(htmlNode, "//body")
	if headNode == nil {
		return
	}
	jss := htmlquery.Find(htmlNode, "//script[contains(@src,'.js')]")
	for _, ele := range jss {
		ele.Parent.RemoveChild(ele)
		for i := 0; i < len(ele.Attr); i++ {
			if ele.Attr[i].Key == "src" {
				//thumb_fruit_misc.png
				val := strings.TrimSpace(ele.Attr[i].Val)
				b, err := d.originalContentByBasePath(val)
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
			}
		}
	}
}
func (d *OneDict) replaceMP3WithSourceBase64(htmlNode *html.Node) {
	// must be a tag?
	divs := htmlquery.Find(htmlNode, "//a[contains(@href,'sound://')]")
	for _, div := range divs {
		for i := 0; i < len(div.Attr); i++ {
			if div.Attr[i].Key == "href" {
				//sound://apple__gb_5.mp3
				mp3Href := strings.TrimPrefix(strings.TrimSpace(div.Attr[i].Val), "sound://")
				b, err := d.originalContentByBasePath(mp3Href)
				if err != nil {
					log.Println(err.Error())
					continue
				}
				// x-wav可以播放
				src := fmt.Sprintf("data:audio/x-wav;base64,%s", base64.StdEncoding.EncodeToString(b))
				val := fmt.Sprintf(`(function () { var audio = new Audio(); audio.src = "%s"; audio.play(); })()`, src)
				div.Attr[i].Key = "onclick"
				div.Attr[i].Val = val
			}
		}
	}
}
func (d *OneDict) replacePng(htmlNode *html.Node) {
	divs := htmlquery.Find(htmlNode, "//img[contains(@src,'.png')]")
	for _, div := range divs {
		for i := 0; i < len(div.Attr); i++ {
			if div.Attr[i].Key == "src" {
				//thumb_fruit_misc.png
				mp3Href := strings.TrimSpace(div.Attr[i].Val)
				b, err := d.originalContentByBasePath(mp3Href)
				if err != nil {
					log.Println(err.Error())
					continue
				}
				// set png href with base64
				div.Attr[i].Val = fmt.Sprintf("data:image/png;base64,%s", base64.StdEncoding.EncodeToString(b))
			}
		}
	}
}

func (d *OneDict) replaceJPG(htmlNode *html.Node) {
	divs := htmlquery.Find(htmlNode, "//img[contains(@src,'.jpg')]")
	for _, div := range divs {
		for i := 0; i < len(div.Attr); i++ {
			if div.Attr[i].Key == "src" {
				val := strings.TrimSpace(div.Attr[i].Val)
				b, err := d.originalContentByBasePath(val)
				if err != nil {
					log.Println(err.Error())
					continue
				}
				// set png href with base64
				div.Attr[i].Val = fmt.Sprintf("data:image/jpeg;base64,%s", base64.StdEncoding.EncodeToString(b))
			}
		}
	}
}
func (d *OneDict) replaceHTMLContent(htmlContent string) (string, error) {
	// 查找正则表达式去除所有的含有css的标签, 因为过滤后的文本的link标签可能在body中，所以需要用正则表达式来解析并替换
	//cssExpr := `<link.*?href="(.*\.css)".*?>`
	cssExpr := `<link[^>]*?href="(.*?\.css)"[^>]*?>`
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
	// 替换的顺序不能变，因为替换后的htmlNode会变化
	d.replacePng(htmlNode)
	d.replaceJPG(htmlNode) // replaceJPG TODO not tested
	// 找出包含所有的script标签并且src属性值包含.js的标签，然后删除这些标签
	d.replaceJS(htmlNode)
	// 找出包含所有的a标签并且href属性值包含sound://的标签，然后删除这些标签
	d.replaceMP3WithSourceBase64(htmlNode)
	// 找出包含所有的link标签并且href属性值包含.css的标签，然后删除这些标签
	d.replaceCSS(htmlNode, allCssNames)
	return htmlquery.OutputHTML(htmlNode, true), nil
}

// getResultByDefaultDict .
func (d *OneDict) getResultByDefaultDict(word string) (string, error) {
	result, ok := d.defaultDictWordMap[word]
	if ok {
		return result, nil
	}
	return "", DataNotFound
}

// ExistInDict .
func (d *OneDict) ExistInDict(word string) bool {
	d.mux.RLock()
	defer d.mux.RUnlock()
	if d.zipFile == "" {
		return false
	}
	_, ok := d.allWordHtmlFileMap[word]
	return ok
}
func (d *OneDict) GetHTMLRenderContentByWord(word string) (string, error) {
	d.mux.RLock()
	defer d.mux.RUnlock()
	if d.zipFile == "" {
		// 走默认字典
		return d.getResultByDefaultDict(word)
	}
	return d.getHTMLRenderContentByWord(word)
}

// SearchByKeyWord .
func (d *OneDict) SearchByKeyWord(keyWord string) []string {
	d.mux.RLock()
	defer d.mux.RUnlock()
	if d.zipFile == "" {
		return SearchByKeyWord(keyWord, d.defaultDictWordMap)
	}
	return SearchByKeyWord(keyWord, d.allWordHtmlFileMap)
}

func (d *OneDict) getHTMLRenderContentByWord(word string) (string, error) {
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
	var needReplace = true
	if strings.HasPrefix(htmlOriginalContent, linkPrefix) {
		word = strings.TrimSpace(strings.TrimPrefix(htmlOriginalContent, linkPrefix))
		htmlOriginalContent = fmt.Sprintf(entryDiv, url.PathEscape(word), word)
		needReplace = false
	}
	// webview必须有完整的html标签
	htmlOriginalContent = fmt.Sprintf(tmpl, word, htmlOriginalContent)
	return htmlOriginalContent, needReplace
}

// getContentByHtmlBasePath
func (d *OneDict) getContentByHtmlBasePath(word, htmlBasePath string) ([]byte, error) {
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
	if strings.HasPrefix(s, linkPrefix) {
		word := strings.TrimSpace(strings.TrimPrefix(s, linkPrefix))
		htmlName, ok := d.finalHtmlBasePathWithOutHtml(word)
		if ok {
			s = fmt.Sprintf(`<big>👉<a href="/%s.html?word=%s">%s</a></big>`, htmlName, url.QueryEscape(word), word)
		}
	}
	s = fmt.Sprintf(tmpl, word, s)
	return []byte(s), nil
}
func (d *OneDict) replaceSoundWithSourceURL(htmlNode *html.Node) {
	// must be a tag?
	divs := htmlquery.Find(htmlNode, "//a[contains(@href,'sound://')]")
	for _, div := range divs {
		for i := 0; i < len(div.Attr); i++ {
			if div.Attr[i].Key == "href" {
				src := fmt.Sprintf("/_sound/%s", strings.TrimPrefix(div.Attr[i].Val, "sound://"))
				val := fmt.Sprintf(`(function(){var audio=new Audio();audio.src='%s';audio.play();})()`, src)
				div.Attr[i].Key = "onclick"
				div.Attr[i].Val = val
			}
		}
	}
}
func (d *OneDict) changeEntryHref(htmlNode *html.Node) {
	divs := htmlquery.Find(htmlNode, "//a[contains(@href,'entry://')]")
	for _, div := range divs {
		for i := 0; i < len(div.Attr); i++ {
			if div.Attr[i].Key == "href" {
				// x-wav可以播放
				val := strings.ReplaceAll(div.Attr[i].Val, "entry://", "/_entry/")
				div.Attr[i].Val = val
			}
		}
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
