package client

import (
	"bufio"
	"context"
	"errors"
	"gorm.io/gorm"
	"io"
	"mywords/model"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

var errSourcesCacheFileExpired = errors.New("sources cache file expired")

func (c *Client) getSourcesFromLocal() ([]string, error) {
	path := filepath.Join(c.rootDir, cacheDir, sourcesCacheFile)
	const expireTime = 24 * time.Hour
	info, err := os.Stat(path)
	if err != nil {
		return nil, err
	}
	if time.Now().Sub(info.ModTime()) > expireTime {
		return nil, errSourcesCacheFileExpired
	}
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	return sourcesFromReader(f)
}

func (c *Client) saveSourcesToLocal(sources []string) (err error) {
	path := filepath.Join(c.rootDir, cacheDir, sourcesCacheFile)
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	defer func() {
		if err != nil {
			_ = os.Remove(path)
		}
	}()
	w := bufio.NewWriter(f)
	for _, source := range sources {
		_, err = w.WriteString(source + "\n")
		if err != nil {
			return err
		}
	}
	return w.Flush()
}

// localFixedSources todo
var localFixedSourcesMap = []string{
	"https://cn.nytimes.com",
	"https://www.bbc.co.uk",
	"https://edition.cnn.com",
	"https://apnews.com",
	"https://www.cbsnews.com",
	"https://www.theguardian.com",
	"https://www.voanews.com",
	"https://time.com",
}

func (c *Client) RefreshPublicSources(ctx context.Context) error {
	sources, err := c.getSourcesFromPublic(ctx)
	if err != nil {
		return err
	}
	// 缓存到本地
	err = c.saveSourcesToLocal(sources)
	if err != nil {
		return err
	}
	return nil
}

func (c *Client) AddSourcesToDB(ctx context.Context, sources []string) error {
	if len(sources) == 0 {
		return nil
	}
	// 过滤掉已经存在的
	sourcesPublic := c.getAllSources(ctx)
	var publicSourcesMap = make(map[string]struct{}, len(sourcesPublic))
	for _, source := range sourcesPublic {
		publicSourcesMap[source] = struct{}{}
	}
	var newSources = make([]string, 0, len(sources))
	for _, source := range sources {
		source = strings.TrimSpace(source)
		_, err := url.Parse(source)
		if err != nil {
			continue
		}
		if _, ok := publicSourcesMap[source]; !ok {
			newSources = append(newSources, source)
		}
	}
	// 保存到db
	var items = make([]model.Sources, 0, len(newSources))
	for _, source := range newSources {
		items = append(items, model.Sources{
			ID:       0,
			Source:   source,
			CreateAt: time.Now().UnixMilli(),
		})
	}
	return c.allDao.Sources.CreateBatch(ctx, items...)
}

func (c *Client) DeleteSourcesFromDB(ctx context.Context, sources []string) error {
	err := c.allDao.GDB().WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		for _, source := range sources {
			if _, err := c.allDao.Sources.DeleteBySource(tx, source); err != nil {
				return err
			}
		}
		return nil
	})
	return err
}

// GetAllSources all error will be ignored because of the localFixedSourcesMap is fixed
func (c *Client) GetAllSources(ctx context.Context) []string {
	return c.getAllSources(ctx)
}
func (c *Client) getAllSources(ctx context.Context) []string {
	sourcesPublic, _ := c.GetSourcesPublic(ctx)
	var publicSourcesMap = make(map[string]struct{}, len(sourcesPublic))
	for _, source := range sourcesPublic {
		publicSourcesMap[source] = struct{}{}
	}
	// 从db获取私有源
	sourcesPrivate, _ := c.allDao.Sources.AllItems(ctx)

	var allSourcesMap = make(map[string]struct{}, len(sourcesPublic)+len(sourcesPrivate)+len(localFixedSourcesMap))
	for _, source := range sourcesPublic {
		allSourcesMap[source] = struct{}{}
	}
	for _, source := range sourcesPrivate {
		allSourcesMap[source.Source] = struct{}{}
	}
	for _, source := range localFixedSourcesMap {
		allSourcesMap[source] = struct{}{}
	}

	var allSources = make([]string, 0, len(allSourcesMap))
	for source := range allSourcesMap {
		allSources = append(allSources, source)
	}
	hosts, _ := c.allDao.FileInfoDao.AllSourceHosts(ctx)
	hostsCountMap := make(map[string]int, len(hosts))
	for _, host := range hosts {
		hostsCountMap[host.Host] = host.Count
	}

	// 排序: 优先级: 按照host出现次数排序 > 公共源 > 私有源 > 按照source排序
	// host  通过getHostFromURL获取
	// order: host count  > public > private > source
	sort.Slice(allSources, func(i, j int) bool {
		sourceI := allSources[i]
		sourceJ := allSources[j]
		hostI := getHostFromURL(sourceI)
		hostJ := getHostFromURL(sourceJ)
		// 公共源优先
		countI := hostsCountMap[hostI]
		countJ := hostsCountMap[hostJ]
		_, isPublicI := publicSourcesMap[sourceI]
		_, isPublicJ := publicSourcesMap[sourceJ]
		if countI != countJ {
			return countI > countJ
		}
		// countI == countJ
		if isPublicI && !isPublicJ {
			return true
		}
		if !isPublicI && isPublicJ {
			return false
		}
		return sourceI < sourceJ
	})
	return allSources
}

func getHostFromURL(source string) string {
	u, err := url.Parse(source)
	if err != nil {
		return source
	}
	return u.Host
}
func (c *Client) GetSourcesPublic(ctx context.Context) ([]string, error) {
	// 先从本地缓存文件获取, 并检查缓存文件时间, 如果超过一天则从公共源获取
	if sources, err := c.getSourcesFromLocal(); err == nil {
		return sources, nil
	}
	sources, err := c.getSourcesFromPublic(ctx)
	if err != nil {
		return nil, err
	}
	// 缓存到本地
	err = c.saveSourcesToLocal(sources)
	if err != nil {
		return nil, err
	}
	return sources, nil
}
func (c *Client) getSourcesFromPublic(ctx context.Context) ([]string, error) {
	const sourceURL = "https://raw.githubusercontent.com/vito-go/assets/refs/heads/master/mywords/sources.list"
	req, err := http.NewRequest("GET", sourceURL, nil)
	if err != nil {
		return nil, err
	}
	// it should be a timeout
	client := &http.Client{Timeout: time.Second * 3, Transport: &http.Transport{
		Proxy: func(*http.Request) (*url.URL, error) {
			return c.netProxy(ctx), nil
		},
	}}
	defer client.CloseIdleConnections()
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	return sourcesFromReader(resp.Body)
}
func sourcesFromReader(r io.Reader) ([]string, error) {
	var sources []string
	scan := bufio.NewScanner(r)

	for scan.Scan() {
		text := scan.Text()
		text = strings.TrimSpace(text)
		// remove empty lines
		if text == "" {
			continue
		}
		// remove line begin with #
		if strings.HasPrefix(text, "#") {
			continue
		}
		sources = append(sources, scan.Text())
	}
	if err := scan.Err(); err != nil {
		return nil, err
	}
	return sources, nil
}
