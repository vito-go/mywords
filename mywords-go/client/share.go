package client

import "C"
import (
	"archive/zip"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"mywords/model"
	"mywords/model/mtype"
	"mywords/pkg/log"
	"net/url"
	"strconv"

	"net"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

func (c *Client) serverHTTPShareBackUpData(w http.ResponseWriter, r *http.Request) {
	if !c.shareOpened.Load() {
		w.WriteHeader(http.StatusForbidden)
		return
	}
	var param ShareFileParam
	defer r.Body.Close()
	b, _ := io.ReadAll(r.Body)
	if len(b) > 0 {
		_ = json.Unmarshal(b, &param)
	}
	srcDataPath := filepath.Join(c.rootDataDir, dataDir)
	remoteHost, _, _ := net.SplitHostPort(r.RemoteAddr)
	if remoteHost == "" {
		remoteHost = r.RemoteAddr
	}
	log.Println("share data begin", "remoteHost", remoteHost)
	// download when it's false
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename=%s`, "mywords-backupdata.zip"))
	err := ZipToWriterWithFilter(w, srcDataPath, &param)
	if err != nil {
		log.Println("share data error", "remoteHost", remoteHost, "err", err.Error())
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
	}
	log.Println("share data done", "remoteHost", remoteHost)
}

// ZipToWriterWithFilter copy from util.ZipToWriter
func ZipToWriterWithFilter(writer io.Writer, zipDir string, param *ShareFileParam) (err error) {
	zw := zip.NewWriter(writer)
	defer func() {
		if err = zw.Close(); err != nil {
			return
		}
	}()
	zipDir = filepath.ToSlash(zipDir)
	baseDir := filepath.Base(zipDir)
	err = filepath.WalkDir(zipDir, func(path string, d fs.DirEntry, err error) error {
		if d.IsDir() {
			return nil
		}
		path = filepath.ToSlash(path)
		pathBase := filepath.Base(path)
		if _, ok := param.AllExistGobGzFileMap[pathBase]; ok {
			return nil
		}
		// TODO 数据同步重新改造
		//if pathBase == chartDataJsonFile && !param.SyncToadyWordCount {
		//	return nil
		//}
		//if pathBase == knownWordsFile && !param.SyncKnownWords {
		//	return nil
		//}
		relPath, err := filepath.Rel(zipDir, path)
		if err != nil {
			return err
		}
		relPath = filepath.ToSlash(relPath)
		zipPath := filepath.ToSlash(filepath.Join(baseDir, relPath))
		w, err := zw.Create(zipPath)
		if err != nil {
			return err
		}
		pathF, err := os.Open(path)
		if err != nil {
			return err
		}
		defer pathF.Close()
		_, err = io.Copy(w, pathF)
		if err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return err
	}
	return nil
}

type ShareFileParam struct {
	AllExistGobGzFileMap map[string]bool `json:"allExistGobGzFileMap"`
	SyncToadyWordCount   bool            `json:"syncToadyWordCount"`
	SyncKnownWords       bool            `json:"syncKnownWords"`
}

type shareServerHandler struct {
	client *Client
	code   int64
}

func (c *shareServerHandler) articleFromSourceURL(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	query := r.URL.Query()
	code := query.Get("code")
	if code != strconv.FormatInt(c.code, 10) {
		w.WriteHeader(http.StatusForbidden)
		_, _ = w.Write([]byte("code not match"))
		return
	}
	updateAt := query.Get("updateAt")
	if updateAt == "" {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte("updateAt is empty"))
		return
	}
	sourceURL := query.Get("sourceURL")
	if sourceURL == "" {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte("sourceURL is empty"))
		return
	}
	info, err := c.client.allDao.FileInfoDao.ItemBySourceUrl(ctx, sourceURL)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(err.Error()))
		return
	}
	if strconv.FormatInt(info.UpdateAt, 10) != updateAt {
		w.WriteHeader(http.StatusNotModified)
		_, _ = w.Write([]byte("updateAt not match"))
		return
	}
	f, err := os.Open(info.FilePath)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(err.Error()))
		return
	}
	defer f.Close()
	name := filepath.Base(info.FilePath)
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename=%s`, name))
	_, err = io.Copy(w, f)
}
func (c *shareServerHandler) shareKnownWords(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	query := r.URL.Query()
	code := query.Get("code")
	if code != strconv.FormatInt(c.code, 10) {
		w.WriteHeader(http.StatusForbidden)
		_, _ = w.Write([]byte("code not match"))
		return
	}
	knownWords, err := c.client.allDao.KnownWordsDao.AllItems(ctx)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(err.Error()))
		return
	}
	data, err := json.Marshal(knownWords)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(err.Error()))
		return
	}
	w.Header().Add("Content-Type", "application/json")
	_, _ = w.Write(data)
}
func (c *shareServerHandler) shareFileInfos(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	query := r.URL.Query()
	code := query.Get("code")
	if code != strconv.FormatInt(c.code, 10) {
		w.WriteHeader(http.StatusForbidden)
		_, _ = w.Write([]byte("code not match"))
		return
	}

	fileInfos, err := c.client.allDao.FileInfoDao.AllItems(ctx)
	if err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		_, _ = w.Write([]byte(err.Error()))
		return
	}

	data, err := json.Marshal(fileInfos)
	if err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		_, _ = w.Write([]byte(err.Error()))
		return
	}
	w.Header().Add("Content-Type", "application/json")
	_, _ = w.Write(data)
}

// SyncData syncKind 1 for knownWords, 2 for fileInfos
func (c *Client) SyncData(host string, port int, code int64, syncKind int) error {

	switch syncKind {
	case 1:
		return c.SyncDataKnownWords(host, port, code)
	case 2:
		return c.SyncDataFileInfos(host, port, code)
	default:
		return fmt.Errorf("syncKind %d not support", syncKind)
	}
}
func (c *Client) SyncDataKnownWords(host string, port int, code int64) (err error) {
	targetURL := fmt.Sprintf("http://%s:%d/share/shareKnownWords?code=%d", host, port, code)
	// set connect timeout
	req, err := http.NewRequest("GET", targetURL, nil)
	if err != nil {
		return err
	}
	httpCli := http.Client{}
	// only set dial timeout
	httpCli.Transport = &http.Transport{
		//DisableKeepAlives: true,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			return net.DialTimeout(network, addr, time.Millisecond*1500)
		},
		Proxy: func(r *http.Request) (*url.URL, error) {
			if net.ParseIP(host).IsPrivate() {
				return nil, nil
			}
			return c.netProxy(context.Background()), nil
		},
	}
	defer httpCli.CloseIdleConnections()
	resp, err := httpCli.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("http status code %d,status %s", resp.StatusCode, resp.Status)
	}
	var result []model.KnownWords
	err = json.NewDecoder(resp.Body).Decode(&result)
	if err != nil {
		return err
	}

	var allWords []string
	var allInster []model.KnownWords
	for i := range result {
		// reset ID
		item := result[i]
		result[i].ID = 0
		allWords = append(allWords, item.Word)
		allInster = append(allInster, item)
		if len(allWords) >= 1000 {
			TX := c.allDao.GDB().WithContext(ctx).Begin()
			err = c.allDao.KnownWordsDao.DeleteByWordsTX(TX, allWords...)
			if err != nil {
				TX.Rollback()
				return err
			}
			err = c.allDao.KnownWordsDao.CreateBatchTX(TX, allInster...)
			if err != nil {
				TX.Rollback()
				return err
			}
			err = TX.Commit().Error
			if err != nil {
				return
			}
			allWords = allWords[:0]
			allInster = allInster[:0]
		}

	}
	TX := c.allDao.GDB().WithContext(ctx).Begin()

	// delete all and insert
	err = c.allDao.KnownWordsDao.DeleteByWordsTX(TX, allWords...)
	if err != nil {
		TX.Rollback()
		return err
	}
	err = c.allDao.KnownWordsDao.CreateBatchTX(TX, result...)
	if err != nil {
		TX.Rollback()
		return err
	}
	err = TX.Commit().Error
	if err != nil {
		return
	}
	_, _ = c.VacuumDB(ctx)
	return nil

}

func (c *Client) downloadArticleFromSourceURL(host string, port int, code int64, item model.FileInfo) (err error) {
	resp, err := http.Get(fmt.Sprintf("http://%s:%d/share/articleFromSourceURL?code=%d&sourceURL=%s&updateAt=%d", host, port, code, item.SourceUrl, item.UpdateAt))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("http status code %d,status %s", resp.StatusCode, resp.Status)
	}
	path := filepath.Join(c.rootDataDir, dataDir, gobFileDir, filepath.Base(item.FilePath))
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = io.Copy(f, resp.Body)
	if err != nil {
		return err
	}
	return nil

}
func (c *Client) SyncDataFileInfos(host string, port int, code int64) error {
	addrURL := fmt.Sprintf("http://%s:%d/share/shareFileInfos?code=%d", host, port, code)
	log.Println("addrURL", addrURL)
	req, err := http.NewRequest("GET", addrURL, nil)
	if err != nil {
		return err
	}
	httpCli := http.Client{}
	// only set dial timeout
	httpCli.Transport = &http.Transport{
		// https://juejin.cn/post/6997294512053878821
		// 重复使用了一个TCP连接，导致的问题，但是对方给的文档也没有提示，暂且猜测对方的api不支持连接保持
		// or set req.Close=true
		//DisableKeepAlives: true,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			return net.DialTimeout(network, addr, time.Millisecond*1500)
		},
		Proxy: func(r *http.Request) (*url.URL, error) {
			if net.ParseIP(host).IsPrivate() {
				return nil, nil
			}
			return c.netProxy(context.Background()), nil
		},
	}
	defer httpCli.CloseIdleConnections()
	resp, err := httpCli.Do(req)
	if err != nil {
		log.Ctx(ctx).Error(err)
		return err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Println(err)
		return err
	}
	if resp.StatusCode != http.StatusOK {
		log.Ctx(ctx).Errorf("http status code: %d,status: %s,--> body: %s", resp.StatusCode, resp.Status, string(body))
		return fmt.Errorf("http status code: %d,status: %s,--> body: %s", resp.StatusCode, resp.Status, string(body))
	}
	var result []model.FileInfo
	err = json.Unmarshal(body, &result)
	if err != nil {
		log.Ctx(ctx).Error("unmarshal error", err)
		return err
	}
	log.Println("result", result)
	for i := range result {
		// reset ID
		item := result[i]
		item.ID = 0
		// 开启事务期间不支持查询? 为什么sqlite3不支持
		if fInfo, err := c.allDao.FileInfoDao.ItemBySourceUrl(ctx, item.SourceUrl); err == nil {
			if _, err = os.Stat(fInfo.FilePath); err == nil {
				log.Println("ignore", item.SourceUrl)
				continue
			}
		}
		item.FilePath = filepath.ToSlash(filepath.Join(c.gobPathByFileName(filepath.Base(item.FilePath))))
		//download file
		err = c.downloadArticleFromSourceURL(host, port, code, item)
		if err != nil {
			log.Ctx(ctx).Error(err.Error())
			continue
		}
		// create file info
		_, err = c.allDao.FileInfoDao.Create(ctx, &item)
		if err != nil {
			log.Ctx(ctx).Error(err.Error())
			return err
		}
	}
	return nil
}

func (c *Client) ShareOpen(port int64, code int64) error {
	c.mux.Lock()
	defer c.mux.Unlock()
	if c.shareServer != nil {
		_ = c.shareServer.Close()
	}
	mux := http.NewServeMux()
	ss := &shareServerHandler{client: c, code: code}
	mux.HandleFunc(fmt.Sprintf("/share/%d", code), c.serverHTTPShareBackUpData)
	mux.HandleFunc(fmt.Sprintf("/share/shareKnownWords"), ss.shareKnownWords)
	mux.HandleFunc(fmt.Sprintf("/share/shareFileInfos"), ss.shareFileInfos)
	mux.HandleFunc(fmt.Sprintf("/share/articleFromSourceURL"), ss.articleFromSourceURL)
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		return err
	}
	srv := &http.Server{Handler: mux}

	c.shareServer = srv
	c.shareOpened.Store(true)
	shareInfo := &mtype.ShareInfo{
		Port: port,
		Code: code,
	}
	err = c.allDao.KeyValueDao.SetShareInfo(ctx, shareInfo)
	if err != nil {
		return err
	}
	log.Println("StartServer success", `port`, port)
	go func() {
		err := srv.Serve(lis)
		if err != nil {
			log.Ctx(ctx).Warn(err.Error())
		}
	}()
	return nil
}

// ShareClosed .
func (c *Client) ShareClosed(port int64, code int64) {
	c.mux.Lock()
	defer c.mux.Unlock()
	if c.shareServer != nil {
		// it's more safe to use Close() in this case.
		// we should close the server immediately, so use Close() instead of Shutdown(), which will wait for all connections to close.
		_ = c.shareServer.Close()
	}
	c.shareOpened.Store(false)
	shareInfo := &mtype.ShareInfo{
		Port: port,
		Code: code,
	}
	err := c.allDao.KeyValueDao.SetShareInfo(ctx, shareInfo)
	if err != nil {
		return
	}
	log.Printf("share server closed, port %d, code %d", port, code)
}

// DropAndReCreateDB 生产环境禁止使用
func (c *Client) DropAndReCreateDB() error {
	var tables []string
	err := c.GDB().Raw("SELECT name FROM sqlite_master WHERE type='table';").Find(&tables).Error
	if err != nil {
		return err
	}
	log.Println("tables", tables)
	for _, table := range tables {
		if table == "sqlite_sequence" {
			continue
		}
		err = c.GDB().Exec("DROP TABLE " + table + ";").Error
		if err != nil {
			return err
		}
	}
	err = c.GDB().Exec(model.SQL).Error
	if err != nil {
		return err
	}
	return nil
}

const defaultSharePort = 8964
const defaultShareCode = 890604

func (c *Client) GetShareInfo() *ShareInfo {
	info, err := c.AllDao().KeyValueDao.QueryShareInfo(ctx)
	if err != nil {
		return &ShareInfo{
			Port: defaultSharePort,
			Code: defaultShareCode,
			Open: false,
		}
	}
	return &ShareInfo{
		Port: info.Port,
		Code: info.Code,
		Open: c.shareOpened.Load(),
	}
}

type ShareInfo struct {
	Port int64 `json:"port"`
	Code int64 `json:"code"`
	Open bool  `json:"open"` //数据不包含在该字段
}
