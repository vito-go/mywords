package artical

import (
	"bytes"
	"crypto/sha1"
	"errors"
	"fmt"
	"github.com/antchfx/xpath"
	htmlquery "github.com/antchfx/xquery/html"
	"github.com/ledongthuc/pdf"
	"io"
	"mywords/dict"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
	"unicode"
)

type Article struct {
	Version      string     `json:"version"`
	LastModified int64      `json:"lastModified"`
	Title        string     `json:"title"`
	SourceUrl    string     `json:"sourceUrl"`
	HTMLContent  string     `json:"htmlContent"`
	MinLen       int        `json:"minLen"`
	TotalCount   int        `json:"totalCount"`
	NetCount     int        `json:"netCount"`
	WordInfos    []WordInfo `json:"wordInfos"`
}
type WordInfo struct {
	Text     string    `json:"text"`
	WordLink string    `json:"wordLink"` // real word
	Count    int64     `json:"count"`
	Sentence []*string `json:"sentence"`
}

func ParseContent(sourceUrl, expr string, respBody []byte, lastModified int64) (*Article, error) {
	return parseContent(sourceUrl, expr, respBody, lastModified)
}

// //div/p//text()[not(ancestor::style or ancestor::a)]

const DefaultXpathExpr = `//div/p//text()[not(ancestor::style)]|//div/span/text()|//div[contains(@class,"article-paragraph")]//text()|//div/text()|//h1/text()|//h2/text()|//h3/text()`

// ParseSourceUrl proxyUrl can be nil
func ParseSourceUrl(sourceUrl string, expr string, proxyUrl *url.URL) (*Article, error) {
	respBody, err := getRespBody(sourceUrl, proxyUrl)
	if err != nil {
		return nil, err
	}
	art, err := parseContent(sourceUrl, expr, respBody, time.Now().UnixMilli())
	if err != nil {
		return nil, err
	}
	art.SourceUrl = sourceUrl
	return art, nil
}
func readPdf(path string) (string, error) {
	f, r, err := pdf.Open(path)
	// remember close file
	defer f.Close()
	if err != nil {
		return "", err
	}
	var buf bytes.Buffer
	b, err := r.GetPlainText()
	if err != nil {
		return "", err
	}
	_, err = buf.ReadFrom(b)
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}
func getLocalFileSourceUrl(path string) (string, error) {
	ext := filepath.Ext(path)
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	sh := sha1.New()
	_, err = io.Copy(sh, f)
	if err != nil {
		return "", err
	}
	sha1Bytes := sh.Sum(nil)
	sourceUrl := fmt.Sprintf("bytes://%x%s", sha1Bytes, ext)
	return sourceUrl, err
}

// ParseLocalFile . only supported txt and pdf
func ParseLocalFile(path string) (*Article, error) {
	info, err := os.Stat(path)
	if err != nil {
		return nil, err
	}
	if info.IsDir() {
		return nil, errors.New("文件夹不支持")
	}
	if info.Size() >= 64<<20 {
		return nil, errors.New("文件过大，不能超过64MB")
	}
	ext := filepath.Ext(path)
	if strings.ToLower(ext) != ".html" {
		return nil, errors.New("file format not supported")
	}
	var sourceUrl string
	sourceUrl, err = getLocalFileSourceUrl(path)
	if err != nil {
		return nil, err
	}
	htmlBody, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return parseContent(sourceUrl, DefaultXpathExpr, htmlBody, time.Now().UnixMilli())
	// todo the other file format to be supported
	var content string
	if strings.ToLower(ext) == ".txt" {
		pureContentBytes, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		content = string(pureContentBytes)
	} else if strings.ToLower(ext) == ".pdf" {
		content, err = readPdf(path)
		if err != nil {
			return nil, err
		}
	} else if strings.ToLower(ext) == ".html" {
		sourceUrl, err = getLocalFileSourceUrl(path)
		if err != nil {
			return nil, err
		}
		htmlBody, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		return parseContent(sourceUrl, DefaultXpathExpr, htmlBody, time.Now().UnixMilli())
	} else {
		return nil, errors.New("file format not supported")
	}
	if sourceUrl == "" {
		sourceUrl, err = getLocalFileSourceUrl(path)
		if err != nil {
			return nil, err
		}
	}
	pureContent := regexp.MustCompile("[\u4e00-\u9fa5，。]").ReplaceAllString(content, "")
	pureContent = regexp.MustCompile(`\s+`).ReplaceAllString(pureContent, " ") + " "
	return articleFromContent("", time.Now().UnixMilli(), filepath.Base(path), sourceUrl, pureContent)
}

// ParseVersion 如果article的文件的version不同，则进入文章页面会重新进行解析，但是不会更新解析时间。
const ParseVersion = "0.0.8"

// var regSentenceSplit = regexp.MustCompile(`[^ ][^ ][^ ][^ ]\. [A-Z“]`)
var regSentenceSplit = regexp.MustCompile(`[^A-Z ][^A-Z ][^A-Z ]\. [A-Z“]`)

const quote = "”"
const minLen = 3

// parseContent 从网页内容中解析出单词
// 输入任意一个网址 获取单词，
// 1 统计英文单词数量
// 2.可以筛选长度
// 3 带三个例句
func parseContent(sourceUrl, expr string, respBody []byte, lastModified int64) (*Article, error) {
	if lastModified <= 0 {
		lastModified = time.Now().UnixMilli()
	}

	if expr == "" {
		expr = DefaultXpathExpr
	}
	_, err := xpath.Compile(expr)
	if err != nil {
		return nil, err
	}
	rootNode, err := htmlquery.Parse(bytes.NewReader(respBody))
	if err != nil {
		return nil, err
	}
	nodes := htmlquery.Find(rootNode, expr)
	var pureContentBuf strings.Builder
	for _, n := range nodes {
		text := strings.TrimSpace(htmlquery.InnerText(n))
		if text == "" {
			continue
		}
		if regexp.MustCompile("[\u4e00-\u9fa5]").MatchString(text) {
			continue
		}
		text = regexp.MustCompile(`\s+`).ReplaceAllString(text, " ") + " "
		pureContentBuf.WriteString(text)
	}
	pureContent := pureContentBuf.String()
	var title string
	titleNode := htmlquery.FindOne(rootNode, "//title/text()")
	if titleNode != nil {
		title = htmlquery.InnerText(titleNode)
	}
	if title == "" {
		title = sourceUrl
	}
	//sentences := strings.SplitAfter(content, ". ")
	// The U.S.
	return articleFromContent(string(respBody), lastModified, title, sourceUrl, pureContent)
}

func articleFromContent(HTMLContent string, lastModified int64, title, sourceUrl, pureContent string) (*Article, error) {
	sentences := make([]string, 0, 512)
	ss := regSentenceSplit.FindAllStringIndex(pureContent, -1)
	var start = 0
	for _, s := range ss {
		// \. [A-Z“]
		//sentences = append(sentences, content[start:s[0]+1])
		//start = s[0] + 2
		sen := []byte(pureContent[start : s[0]+4])
		start = s[0] + 5
		if len(sen) > 2 {
			if sen[len(sen)-1] == quote[1] && sen[len(sen)-2] == quote[0] {
				sen = append(sen, quote[2], '.')
				start += 2
			}
			sentences = append(sentences, string(sen))
		}
	}
	sentences = append(sentences, pureContent[start:])

	var totalCount int
	var wordsMap = make(map[string]int64, 1024)
	var wordsSentences = make(map[string][]*string, 1024)
loopSentences:
	for idx := range sentences {
		sentence := sentences[idx]
		if strings.HasPrefix(sentence, "<div ") {
			continue
		}
		for {
			if len(sentence) < minLen {
				continue loopSentences
			}
			// can not use unicode.IsLetter,Ll/Lu/Lm/Lo/Lt  https://www.compart.com/en/unicode/category
			//if unicode.IsLetter(rune(sentence[0])) {
			//	break
			//}
			first := sentence[0]
			if (first >= 'a' && first <= 'z') || (first >= 'A' && first <= 'Z') {
				break
			}
			sentence = sentence[1:]
		}
		//sentence = regexp.MustCompile(`\s+`).ReplaceAllString(sentence, " ")
		senPointer := &sentences[idx]
		sentenceWords := regexp.MustCompile(fmt.Sprintf("[’A-Za-z-]{%d,}", minLen)).FindAllString(sentence, -1)
		if len(sentenceWords) == 0 {
			continue
		}
		for _, word := range sentenceWords {
			word = strings.TrimPrefix(word, "-")
			if strings.Contains(word, "’") {
				continue
			}
			//word = strings.TrimPrefix(word, "’")
			if _, ok := functionWordsMap[strings.ToLower(word)]; ok {
				continue
			}
			if len(word) < minLen {
				continue
			}
			if !unicode.IsLetter(rune(word[0])) {
				// filter out the word start with non-letter
				continue
			}
			totalCount++
			//if n == 0 && word[0] >= 'A' && word[0] <= 'Z' {
			//	continue
			//}
			// remove all word start with upper letter
			if unicode.IsUpper(rune(word[0])) {
				continue
			}
			wordsMap[word]++
			// 最多保留3个例句
			if len(wordsSentences[word]) < 3 {
				var exist bool
				for _, pointer := range wordsSentences[word] {
					if *pointer == *senPointer {
						exist = true
						break
					}
				}
				if !exist {
					wordsSentences[word] = append(wordsSentences[word], senPointer)
				}

			}
		}

	}
	var WordInfos []WordInfo
	for k, v := range wordsMap {
		wordLink := dict.WordLinkMap[k]
		if wordLink == "" {
			wordLink = k
		}
		WordInfos = append(WordInfos, WordInfo{
			Text:     k,
			WordLink: wordLink,
			Count:    v,
			Sentence: wordsSentences[k],
		})
	}
	sort.Slice(WordInfos, func(i, j int) bool {
		if WordInfos[i].Count > WordInfos[j].Count {
			return true
		} else if WordInfos[i].Count == WordInfos[j].Count {
			return WordInfos[i].Text < WordInfos[j].Text
		} else {
			return false

		}
	})
	c := Article{
		Title:        title,
		SourceUrl:    sourceUrl,
		HTMLContent:  HTMLContent,
		MinLen:       minLen,
		TotalCount:   totalCount,
		NetCount:     len(wordsMap),
		WordInfos:    WordInfos,
		Version:      ParseVersion,
		LastModified: lastModified,
	}
	return &c, nil
}

func isInSlice(in []string, s string) bool {
	for _, ele := range in {
		if ele == s {
			return true
		}
	}
	return false
}

func getRespBody(www string, proxyUrl *url.URL) ([]byte, error) {
	_, err := url.Parse(www)
	if err != nil {
		return nil, errors.New("网址有误")
	}
	method := "GET"
	client := &http.Client{Timeout: time.Second * 5, Transport: &http.Transport{
		Proxy: func(*http.Request) (*url.URL, error) {
			return proxyUrl, nil
		},
	}}
	defer client.CloseIdleConnections()
	req, err := http.NewRequest(method, www, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)")
	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}
	return body, nil
}
