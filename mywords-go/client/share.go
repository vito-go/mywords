package client

import "C"
import (
	"archive/zip"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"mywords/model"
	"mywords/model/mtype"
	"mywords/pkg/log"

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

// RestoreFromShareServer . restore from a zip file,tempDir can be empty
func (c *Client) RestoreFromShareServer(ip string, port int, code int64, syncKnownWords bool, tempDir string, syncToadyWordCount, syncByRemoteArchived bool) error {
	httpUrl := fmt.Sprintf("http://%s:%d/%d", ip, port, code)
	// save to temp dir
	tempZipPath := filepath.Join(tempDir, fmt.Sprintf("mywors-%d.zip", time.Now().UnixMilli()))
	// defer delete temp file
	defer func() {
		_ = os.Remove(tempZipPath)
	}()
	size, err := c.download(httpUrl, syncKnownWords, tempZipPath, syncToadyWordCount)
	if err != nil {
		return err
	}
	if size <= 0 {
		return nil
	}
	err = c.restoreFromBackUpData(syncKnownWords, tempZipPath, syncToadyWordCount, syncByRemoteArchived)
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

func (c *Client) download(httpUrl string, syncKnownWords bool, tempZipPath string, syncToadyWordCount bool) (size int64, err error) {
	allFilePaths, err := c.allDao.FileInfoDao.AllFilePaths(ctx)
	if err != nil {
		return 0, err
	}
	var allFileNames []string
	for _, path := range allFilePaths {
		allFileNames = append(allFileNames, filepath.Base(path))
	}
	allExistGobGzFileMap := make(map[string]bool, len(allFileNames))
	for _, name := range allFileNames {
		allExistGobGzFileMap[name] = true
	}
	param := ShareFileParam{AllExistGobGzFileMap: allExistGobGzFileMap, SyncToadyWordCount: syncToadyWordCount, SyncKnownWords: syncKnownWords}
	fileInfoBytes, _ := json.Marshal(param)
	cli := http.Client{}
	defer cli.CloseIdleConnections()
	// 使用 http.Post 会默认使用http.DefaultClient, 会导致连接不释放.如果服务器关闭,客户端仍然保持连接
	//
	// // Serve a new connection.
	//	func (c *conn) serve(ctx context.Context) {
	resp, err := cli.Post(httpUrl, "application/json", bytes.NewBuffer(fileInfoBytes))
	//resp, err := http.Get(httpUrl)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNoContent {
		log.Println("nothing new to download", "httpUrl", httpUrl, "statusCode", resp.StatusCode)
		return 0, nil
	}
	if resp.StatusCode != http.StatusOK {
		log.Println("download error", "httpUrl", httpUrl, "statusCode", resp.StatusCode)
		return 0, fmt.Errorf("http status code %d", resp.StatusCode)
	}

	f, err := os.Create(tempZipPath)
	if err != nil {
		return 0, err
	}
	defer func() {
		err = f.Close()
	}()
	n, err := io.Copy(f, resp.Body)
	if err != nil {
		return 0, err
	}
	return n, nil
}

func (c *Client) ShareOpen(port int, code int64) error {
	c.mux.Lock()
	defer c.mux.Unlock()
	if c.shareServer != nil {
		_ = c.shareServer.Close()
	}
	mux := http.NewServeMux()
	mux.HandleFunc(fmt.Sprintf("/%d", code), c.serverHTTPShareBackUpData)
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
func (c *Client) ShareClosed() {
	c.mux.Lock()
	defer c.mux.Unlock()
	if c.shareServer != nil {
		// it's more safe to use Close() in this case.
		// we should close the server immediately, so use Close() instead of Shutdown(), which will wait for all connections to close.
		_ = c.shareServer.Close()
	}
	c.shareOpened.Store(false)
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
	Port int   `json:"port"`
	Code int64 `json:"code"`
	Open bool  `json:"open"` //数据不包含在该字段
}
