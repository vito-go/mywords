package dict

import (
	"archive/zip"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	htmlquery "github.com/antchfx/xquery/html"
	"golang.org/x/net/html"
	"io"
	"mywords/mylog"
	"net/url"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"sync"
)

type OneDict struct {
	zipFile            string
	zipFileMap         map[string]*zip.File
	allWordHtmlFileMap map[string]string // word:htmlPath htmlPath不带html后缀
	zipReadCloser      *zip.ReadCloser
	jsCssCache         sync.Map // key:htmlBasePath, value:htmlContent string:[]byte
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
func NewDictZip(zipFile string) (*OneDict, error) {
	z, err := zip.OpenReader(zipFile)
	if err != nil {
		return nil, err
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
				return nil, err
			}
		}
	}
	if len(allWordHtmlFileMap) == 0 {
		_ = z.Close()
		return nil, fmt.Errorf("字典文件中没有找到 %s", wordHtmlMapJsonName)
	}
	return &OneDict{
		zipFile:            zipFile,
		zipFileMap:         zipFileMap,
		allWordHtmlFileMap: allWordHtmlFileMap,
		zipReadCloser:      z,
	}, nil
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
	if d == nil {
		return
	}
	d.zipFileMap = nil
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
				mp3Href := strings.TrimSpace(ele.Attr[i].Val)
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
func (d *OneDict) replaceMP3(htmlNode *html.Node) {
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
func (d *OneDict) replacePng(htmlNode *html.Node) {
	pngs := htmlquery.Find(htmlNode, "//img[contains(@src,'.png')]")
	for _, ele := range pngs {
		for i := 0; i < len(ele.Attr); i++ {
			if ele.Attr[i].Key == "src" {
				//thumb_fruit_misc.png
				mp3Href := strings.TrimSpace(ele.Attr[i].Val)
				b, err := d.originalContentByBasePath(mp3Href)
				if err != nil {
					mylog.Error(err.Error())
					continue
				}
				// set png href with base64
				ele.Attr[i].Val = fmt.Sprintf("data:image/png;base64,%s", base64.StdEncoding.EncodeToString(b))
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
	// 找出包含所有的script标签并且src属性值包含.js的标签，然后删除这些标签
	d.replaceJS(htmlNode)
	//  找出包含所有的a标签并且href属性值包含.mp3的标签，然后删除这些标签
	d.replaceMP3(htmlNode)
	// 找出包含所有的link标签并且href属性值包含.css的标签，然后删除这些标签
	d.replaceCSS(htmlNode, allCssNames)
	return htmlquery.OutputHTML(htmlNode, true), nil
}

func (d *OneDict) GetHTMLRenderContentByWord(word string) (string, error) {
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

// getContentByHtmlBasePath htmlBasePath 带html后缀
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
func (d *OneDict) addOnClickMp3(htmlNode *html.Node) {
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
func (d *OneDict) changeEntreHref(htmlNode *html.Node) {
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
