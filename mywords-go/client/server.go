package client

import "C"
import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"context"
	"encoding/gob"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/antchfx/xpath"
	"gorm.io/gorm"
	"io"
	"mywords/artical"
	"mywords/client/dao"
	"mywords/model"
	"mywords/model/mtype"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"sync/atomic"
	"time"
)

func (c *Client) AllDao() *dao.AllDao {
	return c.allDao
}

type config struct {
	ProxyUrl  string `json:"proxyUrl"`
	SharePort int    `json:"sharePort"`
	ShareCode int64  `json:"shareCode"`
}

func (c *config) Clone() *config {
	return &config{
		ProxyUrl:  c.ProxyUrl,
		SharePort: c.SharePort,
		ShareCode: c.ShareCode,
	}
}

const (
	dataDir    = `data`         // 存放背单词的目录
	gobFileDir = "gob_gz_files" // a.txt.gob, b.txt.gob, c.txt.gob ...
)

// RootDataDir . root data dir
func (c *Client) RootDataDir() string {
	return c.rootDataDir
}

func (c *Client) DataDir() string {
	return filepath.ToSlash(filepath.Join(c.rootDataDir, dataDir))
}

func (c *Client) netProxy(ctx context.Context) *url.URL {
	proxy, err := c.allDao.KeyValueDao.Proxy(ctx)
	if err != nil {
		return nil
	}

	u, err := url.Parse(proxy)
	if err != nil {
		return nil
	}
	return u
}

func (c *Client) ProxyURL() string {
	u := c.netProxy(ctx)
	if u == nil {
		return ""
	}
	return u.String()
}

func (c *Client) restoreFromBackUpDataFileInfoFile(f *zip.File) (map[string]model.FileInfo, error) {
	r, err := f.Open()
	if err != nil {
		return nil, err
	}
	defer r.Close()
	b, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}
	if len(b) == 0 {
		return make(map[string]model.FileInfo), nil
	}
	var fileInfoMap = make(map[string]model.FileInfo)
	err = json.Unmarshal(b, &fileInfoMap)
	if err != nil {
		return nil, err
	}
	return fileInfoMap, nil
}

func (c *Client) RestoreFromBackUpData(syncKnownWords bool, backUpDataZipPath string, syncToadyWordCount bool, syncByRemoteArchived bool) error {
	return c.restoreFromBackUpData(syncKnownWords, backUpDataZipPath, syncToadyWordCount, syncByRemoteArchived)
}
func (c *Client) restoreFromBackUpData(syncKnownWords bool, backUpDataZipPath string, syncToadyWordCount bool, syncByRemoteArchived bool) error {
	r, err := zip.OpenReader(backUpDataZipPath)
	if err != nil {
		return err
	}
	defer r.Close()
	var fileMap = make(map[string]*zip.File)
	for _, f := range r.File {
		fileMap[f.Name] = f
	}

	if syncKnownWords {

		// TODO
	}
	// todo
	return nil
}

// FixMyKnownWords .
func (c *Client) FixMyKnownWords() error {
	return nil
}

// SetProxyUrl .
func (c *Client) SetProxyUrl(proxyUrl string) error {
	return c.AllDao().KeyValueDao.SetProxyURL(ctx, proxyUrl)

}

// SetXpathExpr . usually for debug
func (c *Client) SetXpathExpr(expr string) (err error) {
	if expr == "" {
		c.xpathExpr = artical.DefaultXpathExpr
		return nil
	}
	_, err = xpath.Compile(expr)
	if err != nil {
		return err
	}
	c.xpathExpr = expr
	return nil
}

var ctx = context.TODO()

func (c *Client) ReparseArticleFileInfo(id int64) (*artical.Article, error) {
	fileInfo, err := c.AllDao().FileInfoDao.ItemByID(ctx, id)
	if err != nil {
		return nil, err
	}
	art, err := c.ArticleFromGobGZPath(fileInfo.FilePath)
	if err != nil {
		return nil, err
	}
	art, err = artical.ParseContent(art.SourceUrl, []byte(art.HTMLContent))
	if err != nil {
		return nil, err
	}
	path := c.gobPathByFileName(art.GenFileName())
	fileSize, err := art.SaveToFile(path)
	if err != nil {
		return nil, err
	}
	fileInfo.Title = art.Title
	fileInfo.Size = fileSize
	fileInfo.TotalCount = art.TotalCount
	fileInfo.NetCount = art.NetCount
	fileInfo.UpdateAt = time.Now().UnixMilli()
	err = c.AllDao().FileInfoDao.Update(ctx, fileInfo)
	if err != nil {
		return nil, err
	}
	return art, nil
}
func (c *Client) RenewArticleFileInfo(id int64) (*artical.Article, error) {
	fileInfo, err := c.AllDao().FileInfoDao.ItemByID(ctx, id)
	if err != nil {
		return nil, err
	}
	sourceUrl := fileInfo.SourceUrl
	art, err := artical.ParseSourceUrl(sourceUrl, c.netProxy(ctx))
	if err != nil {
		return nil, err
	}
	path := c.gobPathByFileName(art.GenFileName())
	fileSize, err := art.SaveToFile(path)
	if err != nil {
		return nil, err
	}
	fileInfo.Title = art.Title
	fileInfo.Size = fileSize
	fileInfo.TotalCount = art.TotalCount
	fileInfo.NetCount = art.NetCount
	fileInfo.UpdateAt = time.Now().UnixMilli()
	err = c.AllDao().FileInfoDao.Update(ctx, fileInfo)
	if err != nil {
		return nil, err
	}
	return art, nil
}
func (c *Client) NewArticleFileInfoBySourceURL(sourceUrl string) (*artical.Article, error) {
	u, err := url.Parse(sourceUrl)
	if err != nil {
		return nil, err
	}
	// only support http and https
	if u.Scheme != "http" && u.Scheme != "https" {
		return nil, fmt.Errorf("only support http and https")
	}
	host := u.Host
	if host == "" {
		return nil, fmt.Errorf("host is empty")
	}
	art, err := artical.ParseSourceUrl(sourceUrl, c.netProxy(ctx))
	if err != nil {
		return nil, err
	}
	path := c.gobPathByFileName(art.GenFileName())
	fileSize, err := art.SaveToFile(path)
	if err != nil {
		return nil, err
	}
	// save FileInfo
	fileInfo := model.FileInfo{
		ID:         0,
		Title:      art.Title,
		SourceUrl:  sourceUrl,
		FilePath:   path,
		Host:       host, // FIXME
		Size:       fileSize,
		TotalCount: art.TotalCount,
		NetCount:   art.NetCount,
		Archived:   false,
		CreateAt:   time.Now().UnixMilli(),
		UpdateAt:   time.Now().UnixMilli(),
	}
	_, err = c.AllDao().FileInfoDao.Create(ctx, &fileInfo)
	return art, err
}

func (c *Client) AllKnownWordMap() map[mtype.WordKnownLevel][]string {
	items, err := c.allDao.KnownWordsDao.AllItems(ctx)
	if err != nil {
		return nil
	}
	var resultMap = make(map[mtype.WordKnownLevel][]string, 3)
	for _, item := range items {
		resultMap[item.Level] = append(resultMap[item.Level], item.Word)
	}
	return resultMap
}
func (c *Client) TodayKnownWordMap() map[mtype.WordKnownLevel][]string {
	createDay, _ := strconv.ParseInt(time.Now().Format("2006-01-02"), 10, 64)
	items, err := c.allDao.KnownWordsDao.AllItemsByCreateDay(ctx, createDay)
	if err != nil {
		return nil
	}
	var resultMap = make(map[mtype.WordKnownLevel][]string, 3)
	for _, item := range items {
		resultMap[item.Level] = append(resultMap[item.Level], item.Word)
	}
	return resultMap
}

func (c *Client) ArticleFromGobGZPath(filePath string) (*artical.Article, error) {
	b, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}
	return c.articleFromGobGZContent(b)

}
func (c *Client) articleFromGobGZContent(b []byte) (*artical.Article, error) {
	gzReader, err := gzip.NewReader(bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	defer gzReader.Close()
	var art artical.Article
	//gob unmarshal
	err = gob.NewDecoder(gzReader).Decode(&art)
	if err != nil {
		return nil, err
	}
	return &art, nil
}

// DeleteGobFile delete gob file and update fileInfoMap
func (c *Client) DeleteGobFile(id int64) error {
	return c.deleteGobFile(id)
}
func (c *Client) deleteGobFile(id int64) error {
	item, err := c.AllDao().FileInfoDao.ItemByID(ctx, id)
	if err != nil {
		return err
	}
	_, err = c.AllDao().FileInfoDao.DeleteById(ctx, item.ID)
	if err != nil {
		return err
	}
	err = os.Remove(item.FilePath)
	if err != nil {
		return err
	}
	return nil
}
func (c *Client) gobPathByFileName(fileName string) string {
	return filepath.Join(c.rootDataDir, dataDir, gobFileDir, fileName)
}

func (c *Client) ParseAndSaveArticleFromFile(filePath string) (*artical.Article, error) {
	return nil, errors.New("not implemented")
}

var debug = atomic.Bool{}

type CodeContent struct {
	Code    int64
	Content any
}

// VacuumDB reorganizes the database file to use disk space more efficiently.
// VACUUM is a SQLite command that reorganizes the database file to use disk space more efficiently.
// It can remove free pages from the database file, reducing the size of the database file.
func (c *Client) VacuumDB(ctx context.Context) (int64, error) {
	tx := c.gdb.WithContext(ctx).Exec("VACUUM")
	if tx.Error != nil {
		return 0, tx.Error
	}
	return tx.RowsAffected, nil
}

var ErrMessageChanFull = errors.New("message chan full")
var ErrMessageChanClosed = errors.New("message chan closed")
var ErrMessageChanTimeout = errors.New("message chan timeout")

// HTTPAddr returns the pprof listen address
func (c *Client) HTTPAddr() string {
	if c.pprofListen == nil {
		return ""
	}
	port := c.pprofListen.Addr().(*net.TCPAddr).Port
	return fmt.Sprintf("http://127.0.0.1:%d/debug/pprof/", port)
}

func (c *Client) Close() error {
	if c.closed.Swap(true) {
		return nil
	}
	d, err := c.gdb.DB()
	if err != nil {
		return err
	}

	if c.pprofListen != nil {
		_ = c.pprofListen.Close()
	}
	return d.Close()
}
func (c *Client) GDB() *gorm.DB {
	return c.gdb
}

// DBSize returns the size of the database file
func (c *Client) DBSize() (int64, error) {
	info, err := os.Stat(c.dbPath)
	if err != nil {
		return 0, err
	}
	return info.Size(), nil
}
func (c *Client) InitCreateTables() error {
	if err := c.gdb.Exec(model.SQL).Error; err != nil {
		return err
	}
	return nil
}

// DeleteOldVersionFile .
func (c *Client) DeleteOldVersionFile() error {
	return c.deleteOldVersionFile()
}
func (c *Client) RestoreFromOldVersionData() error {
	// restore
	if err := c.restoreFileInfoFromArchived(); err != nil {
		return err
	}
	// restore
	if err := c.restoreFileInfoFromNotArchived(); err != nil {
		return err
	}
	// restore
	if err := c.restoreFromDailyChartDataFile(); err != nil {
		return err
	}
	return nil
}
