package artical

import (
	"bytes"
	"errors"
	"fmt"
	"github.com/antchfx/xpath"
	htmlquery "github.com/antchfx/xquery/html"
	"io"
	"mywords/dict"
	"net/http"
	"net/url"
	"regexp"
	"sort"
	"strings"
	"time"
	"unicode"
)

type Article struct {
	Version     string     `json:"version"`
	Title       string     `json:"title"`
	SourceUrl   string     `json:"sourceUrl"`
	HTMLContent string     `json:"htmlContent"`
	MinLen      int        `json:"minLen"`
	TopN        []string   `json:"topN"`
	TotalCount  int        `json:"totalCount"`
	NetCount    int        `json:"netCount"`
	WordInfos   []WordInfo `json:"wordInfos"`
}
type WordInfo struct {
	Text     string    `json:"text"`
	WordLink string    `json:"wordLink"` // real word
	Count    int64     `json:"count"`
	Sentence []*string `json:"sentence"`
}

// ParseContent 从网页内容中解析出单词
// 输入任意一个网址 获取单词，
// 1 统计英文单词数量
// 2.可以筛选长度
// 3 带三个例句
func ParseContent(sourceUrl, expr string, respBody []byte) (*Article, error) {
	return parseContent(sourceUrl, expr, respBody)
}

// ParseSourceUrl proxyUrl can be nil
func ParseSourceUrl(sourceUrl string, expr string, proxyUrl *url.URL) (*Article, error) {
	respBody, err := getRespBody(sourceUrl, proxyUrl)
	if err != nil {
		return nil, err
	}
	art, err := parseContent(sourceUrl, expr, respBody)
	if err != nil {
		return nil, err
	}
	art.SourceUrl = sourceUrl
	return art, nil
}

// ParseVersion 如果article的文件的version不同，应该重新进行解析。
const ParseVersion = "0.0.4"

var regSentenceSplit = regexp.MustCompile(`[^ ][^ ][^ ][^ ]\. [A-Z“]`)

var quote = "“"

func parseContent(sourceUrl, expr string, respBody []byte) (*Article, error) {
	const (
		minLen = 4
		topN   = 50
	)
	_, err := xpath.Compile(expr)
	if err != nil {
		return nil, err
	}
	rootNode, err := htmlquery.Parse(bytes.NewReader(respBody))
	if err != nil {
		return nil, err
	}
	nodes := htmlquery.Find(rootNode, expr)
	var contentBuf strings.Builder
	for _, n := range nodes {
		text := strings.TrimSpace(htmlquery.InnerText(n))
		if text == "" {
			continue
		}
		if regexp.MustCompile("[\u4e00-\u9fa5]").MatchString(text) {
			continue
		}
		text = regexp.MustCompile(`\s+`).ReplaceAllString(text, " ") + " "
		contentBuf.WriteString(text)
	}
	content := contentBuf.String()
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
	sentences := make([]string, 0, 512)
	ss := regSentenceSplit.FindAllStringIndex(content, -1)
	var start = 0
	for _, s := range ss {
		// \. [A-Z“]
		//sentences = append(sentences, content[start:s[0]+1])
		//start = s[0] + 2
		sen := []byte(content[start : s[0]+5])
		if len(sen) > 2 {
			if sen[len(sen)-1] == quote[1] && sen[len(sen)-2] == quote[0] {
				sen = append(sen, quote[2])
				sentences = append(sentences, string(sen))
			}
		}
		start = s[0] + 6
	}
	sentences = append(sentences, content[start:])

	var totalCount int
	var wordsMap = make(map[string]int64, 1024)
	var wordsSentences = make(map[string][]*string, 1024)
	for _, sentence := range sentences {
		if strings.HasPrefix(sentence, "<div ") {
			continue
		}
		for {
			if len(sentence) < minLen {
				continue
			}
			if unicode.IsLetter(rune(sentence[0])) {
				break
			}
			sentence = sentence[1:]
		}
		//sentence = regexp.MustCompile(`\s+`).ReplaceAllString(sentence, " ")
		s := sentence
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
			if _, ok := meaninglessMap[strings.ToLower(word)]; ok {
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
			if len(wordsSentences[word]) < 3 {
				var exist bool
				for _, pointer := range wordsSentences[word] {
					if *pointer == s {
						exist = true
						break
					}
				}
				if !exist {
					wordsSentences[word] = append(wordsSentences[word], &s)
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
	var topNWords []string

	for i := 0; i < len(WordInfos); i++ {
		if len(topNWords) >= topN {
			break
		}
		topNWords = append(topNWords, WordInfos[i].Text)
	}
	c := Article{
		Title:       title,
		SourceUrl:   sourceUrl,
		HTMLContent: string(respBody),
		MinLen:      minLen,
		TotalCount:  totalCount,
		NetCount:    len(wordsMap),
		WordInfos:   WordInfos,
		TopN:        topNWords,
		Version:     ParseVersion,
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

// define meaninglessMap
var meaninglessMap = map[string]struct{}{
	"a": {}, "an": {}, "the": {}, "I": {}, "you": {}, "he": {}, "she": {}, "it": {}, "we": {}, "they": {}, "me": {}, "him": {}, "her": {}, "us": {}, "them": {}, "in": {},
	"on": {}, "at": {}, "over": {}, "under": {}, "between": {}, "from": {},
	"to": {}, "with": {}, "about": {}, "and": {}, "or": {}, "but": {},
	"although": {}, "because": {}, "if": {}, "unless": {}, "since": {},
	"until": {}, "be": {}, "do": {}, "have": {}, "can": {}, "could": {},
	"may": {}, "might": {}, "must": {}, "shall": {}, "should": {}, "will": {},
	"would": {}, "oh": {}, "ah": {}, "wow": {}, "alas": {}, "ouch": {}, "hurrah": {},
	"very": {}, "quite": {}, "rather": {}, "just": {}, "so": {}, "too": {},
	"enough": {}, "almost": {}, "only": {}, "when": {}, "where": {}, "why": {},
	"how": {}, "what": {}, "that": {}, "who": {}, "whom": {}, "whose": {},
	"which": {},
}
