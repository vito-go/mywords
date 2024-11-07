package sources

import (
	"bufio"
	"net/http"
	"net/url"
	"strings"
	"time"
)

func GetSources(proxy *url.URL) ([]string, error) {
	const sourceURL = "https://raw.githubusercontent.com/vito-go/assets/refs/heads/dev-sources/mywords/sources.list"
	req, err := http.NewRequest("GET", sourceURL, nil)
	if err != nil {
		return nil, err
	}
	client := &http.Client{Timeout: time.Second * 6, Transport: &http.Transport{
		Proxy: func(*http.Request) (*url.URL, error) {
			return url.Parse("http://192.168.89.103:19480")
		},
	}}
	defer client.CloseIdleConnections()
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	scanner := bufio.NewScanner(resp.Body)
	var sources []string
	for scanner.Scan() {
		text := scanner.Text()
		text = strings.TrimSpace(text)
		// remove empty lines
		if text == "" {
			continue
		}
		// remove line begin with #
		if strings.HasPrefix(text, "#") {
			continue
		}
		sources = append(sources, scanner.Text())
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return sources, nil
}
