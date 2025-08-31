package artical

import (
	"bytes"
	"compress/gzip"
	"crypto/sha1"
	"encoding/gob"
	"errors"
	"fmt"
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

	"github.com/antchfx/xpath"
	htmlquery "github.com/antchfx/xquery/html"
)

type Article struct {
	Version     string `json:"version"`
	Title       string `json:"title"`
	SourceUrl   string `json:"sourceUrl"`
	HTMLContent string `json:"htmlContent"`
	MinLen      int    `json:"minLen"`
	TotalCount  int    `json:"totalCount"`
	NetCount    int    `json:"netCount"`
	// todo 重复的句子改革
	WordInfos    []WordInfo `json:"wordInfos"`
	AllSentences []string   `json:"allSentences"`
}

func (art *Article) SaveToFile(path string) (int, error) {
	//gob marshal
	var buf bytes.Buffer
	err := gob.NewEncoder(&buf).Encode(art)
	if err != nil {
		return 0, err
	}
	//save gob file
	var bufGZ bytes.Buffer
	gz := gzip.NewWriter(&bufGZ)
	fileSize, err := gz.Write(buf.Bytes())
	if err != nil {
		return 0, err
	}
	err = gz.Close()
	if err != nil {
		return 0, err
	}
	err = os.WriteFile(path, bufGZ.Bytes(), 0644)
	if err != nil {
		return 0, err
	}
	return fileSize, nil
}

const gobGzFileSuffix = ".gob.gz" // file_infos.json index file

func (art *Article) GenFileName() string {
	fileName := fmt.Sprintf("%x%s", sha1.Sum([]byte(art.HTMLContent)), gobGzFileSuffix)
	return fileName

}

type WordInfo struct {
	Text        string    `json:"text"`
	WordLink    string    `json:"wordLink"` // real word
	Count       int64     `json:"count"`
	SentenceIds []int     `json:"sentenceIds"`
	sentence    []*string // internal use
}

// //div/p//text()[not(ancestor::style or ancestor::a)]

const DefaultXpathExpr = `//div/p//text()[not(ancestor::style)]|//div/span/text()|//div[contains(@class,"article-paragraph")]//text()|//div/text()|//h1/text()|//h2/text()|//h3/text()`

// ParseSourceUrl proxyUrl can be nil
func ParseSourceUrl(sourceUrl string, proxyUrl *url.URL) (*Article, error) {
	respBody, err := getRespBody(sourceUrl, proxyUrl)
	if err != nil {
		return nil, err
	}
	art, err := parseContent(sourceUrl, respBody)
	if err != nil {
		return nil, err
	}
	return art, nil
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

// ParseLocalFile . only supported html
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
	return parseContent(sourceUrl, htmlBody)
	// TODO: the other file format to be supported, how to preview txt file?
	/*

	   var content string
	   	if strings.ToLower(ext) == ".txt" {
	   		pureContentBytes, err := os.ReadFile(path)
	   		if err != nil {
	   			return nil, err
	   		}
	   		content = string(pureContentBytes)
	   	} else {
	   		return nil, errors.New("file format not supported")
	   	}
	   	pureContent := regexp.MustCompile("[\u4e00-\u9fa5，。]").ReplaceAllString(content, "")
	   	pureContent = regexp.MustCompile(`\s+`).ReplaceAllString(pureContent, " ") + " "
	   	return buildArticleFromContent("", filepath.Base(path), sourceUrl, pureContent)

	*/
}

// shy [194 173]
// const shy = `­`
var shy = string([]byte{194, 173})

// ParseVersion 如果article的文件的version不同，则进入文章页面会重新进行解析，但是不会更新解析时间。
const ParseVersion = "4.3.8"

// var regSentenceSplit = regexp.MustCompile(`[^ ][^ ][^ ][^ ]\. [A-Z“]`)
var regSentenceSplit = regexp.MustCompile(`[^A-Z ][^A-Z ][^A-Z ]\. [A-Z“<]`)

const quote = "”"
const minLen = 3

func ParseContent(sourceUrl string, htmlContent []byte) (*Article, error) {
	return parseContent(sourceUrl, htmlContent)
}
func parseContent(sourceUrl string, htmlContent []byte) (*Article, error) {
	expr := DefaultXpathExpr
	_, err := xpath.Compile(expr)
	if err != nil {
		return nil, err
	}
	rootNode, err := htmlquery.Parse(bytes.NewReader(htmlContent))
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
		// &shy;
		text = strings.ReplaceAll(text, shy, "")
		pureContentBuf.WriteString(text)
	}
	pureContent := pureContentBuf.String()
	var title string
	titleNode := htmlquery.FindOne(rootNode, "//title/text()")
	if titleNode != nil {
		title = htmlquery.InnerText(titleNode)
	}
	if title == "" {
		title = filepath.Base(sourceUrl)
	}
	//sentences := strings.SplitAfter(content, ". ")
	// The U.S.
	return buildArticleFromContent(string(htmlContent), title, sourceUrl, pureContent)
}

func buildArticleFromContent(HTMLContent string, title, sourceUrl, pureContent string) (*Article, error) {
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
			if _, ok := dict.DefaultDictWordMap[word]; !ok {
				if _, ok = dict.WordLinkMap[word]; !ok {
					continue
				}
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
	var wordInfos []WordInfo
	for k, v := range wordsMap {
		wordLink := dict.WordLinkMap[k]
		if wordLink == "" {
			wordLink = k
		}
		wordInfos = append(wordInfos, WordInfo{
			Text:     k,
			WordLink: wordLink,
			Count:    v,
			sentence: wordsSentences[k],
		})
	}
	sort.Slice(wordInfos, func(i, j int) bool {
		if wordInfos[i].Count > wordInfos[j].Count {
			return true
		} else if wordInfos[i].Count == wordInfos[j].Count {
			return wordInfos[i].Text < wordInfos[j].Text
		} else {
			return false
		}
	})

	var sentencePointerMap = make(map[*string]int, len(wordInfos))
	var sentencePointerSlice = make([]*string, 0, len(wordInfos))
	for _, wordInfo := range wordInfos {
		for _, pointer := range wordInfo.sentence {
			if _, ok := sentencePointerMap[pointer]; !ok {
				sentencePointerMap[pointer] = len(sentencePointerSlice)
				sentencePointerSlice = append(sentencePointerSlice, pointer)
			}
		}
	}
	for i := range wordInfos {
		for _, pointer := range wordInfos[i].sentence {
			wordInfos[i].SentenceIds = append(wordInfos[i].SentenceIds, sentencePointerMap[pointer])
		}
	}
	var allSentences = make([]string, len(sentencePointerSlice))
	for i, pointer := range sentencePointerSlice {
		allSentences[i] = *pointer
	}
	c := Article{
		Title:        title,
		SourceUrl:    sourceUrl,
		HTMLContent:  HTMLContent,
		MinLen:       minLen,
		TotalCount:   totalCount,
		NetCount:     len(wordsMap),
		WordInfos:    wordInfos,
		Version:      ParseVersion,
		AllSentences: allSentences,
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
