package server

import (
	"archive/zip"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"mywords/mylog"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

func (s *Server) serverHTTPShareBackUpData(w http.ResponseWriter, r *http.Request) {
	var param ShareFileParam
	defer r.Body.Close()
	b, _ := io.ReadAll(r.Body)
	if len(b) > 0 {
		_ = json.Unmarshal(b, &param)
	}
	srcDataPath := filepath.Join(s.rootDataDir, dataDir)
	remoteHost, _, _ := net.SplitHostPort(r.RemoteAddr)
	if remoteHost == "" {
		remoteHost = r.RemoteAddr
	}
	mylog.Info("share data begin", "remoteHost", remoteHost)
	// download when it's false
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename=%s`, "mywords-backupdata.zip"))
	err := ZipToWriterWithFilter(w, srcDataPath, &param)
	if err != nil {
		mylog.Error("share data error", "remoteHost", remoteHost, "err", err.Error())
		w.WriteHeader(500)
		w.Write([]byte(err.Error()))
	}
	mylog.Info("share data done", "remoteHost", remoteHost)
}

// ZipToWriterWithFilter copy from util.ZipToWriter
func ZipToWriterWithFilter(writer io.Writer, zipDir string, param *ShareFileParam) (err error) {
	zw := zip.NewWriter(writer)
	defer func() {
		if err = zw.Close(); err != nil {
			return
		}
	}()
	baseDir := filepath.Base(zipDir)
	err = filepath.WalkDir(zipDir, func(path string, d fs.DirEntry, err error) error {
		if d.IsDir() {
			return nil
		}
		pathBase := filepath.Base(path)
		if _, ok := param.AllExistGobGzFileMap[pathBase]; ok {
			return nil
		}
		if pathBase == chartDataJsonFile && !param.SyncToadyWordCount {
			return nil
		}
		if pathBase == knownWordsFile && !param.SyncKnownWords {
			return nil
		}
		relPath, err := filepath.Rel(zipDir, path)
		if err != nil {
			return err
		}
		zipPath := filepath.Join(baseDir, relPath)
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
func (s *Server) RestoreFromShareServer(ip string, port int, code int64, syncKnownWords bool, tempDir string, syncToadyWordCount, syncByRemoteArchived bool) error {
	httpUrl := fmt.Sprintf("http://%s:%d/%d", ip, port, code)
	// save to temp dir
	tempZipPath := filepath.Join(tempDir, fmt.Sprintf("mywors-%d.zip", time.Now().UnixMilli()))
	// defer delete temp file
	defer func() {
		_ = os.Remove(tempZipPath)
	}()
	size, err := s.download(httpUrl, syncKnownWords, tempZipPath, syncToadyWordCount)
	if err != nil {
		return err
	}
	if size <= 0 {
		return nil
	}
	err = s.restoreFromBackUpData(syncKnownWords, tempZipPath, syncToadyWordCount, syncByRemoteArchived)
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

func (s *Server) download(httpUrl string, syncKnownWords bool, tempZipPath string, syncToadyWordCount bool) (size int64, err error) {
	allExistGobGzFileMap := make(map[string]bool, len(s.fileInfoMap)+len(s.fileInfoMap))
	for k, _ := range s.fileInfoMap {
		allExistGobGzFileMap[k] = true
	}
	for k, _ := range s.fileInfoArchivedMap {
		allExistGobGzFileMap[k] = true
	}
	param := ShareFileParam{AllExistGobGzFileMap: allExistGobGzFileMap, SyncToadyWordCount: syncToadyWordCount, SyncKnownWords: syncKnownWords}
	fileInfoBytes, _ := json.Marshal(param)
	resp, err := http.Post(httpUrl, "application/json", bytes.NewBuffer(fileInfoBytes))
	//resp, err := http.Get(httpUrl)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNoContent {
		mylog.Info("nothing new to download", "httpUrl", httpUrl, "statusCode", resp.StatusCode)
		return 0, nil
	}
	if resp.StatusCode != http.StatusOK {
		mylog.Error("download error", "httpUrl", httpUrl, "statusCode", resp.StatusCode)
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

// ShareOpen .
func (s *Server) ShareOpen(port int, code int64) error {
	s.mux.Lock()
	defer s.mux.Unlock()
	if s.shareListener != nil {
		_ = s.shareListener.Close()
	}
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		return err
	}
	s.shareListener = lis
	mux := http.NewServeMux()
	mux.HandleFunc(fmt.Sprintf("/%d", code), s.serverHTTPShareBackUpData)
	var chanErr = make(chan error, 1)
	go func() {
		if err = http.Serve(lis, mux); err != nil {
			chanErr <- err
		}
	}()
	select {
	case err = <-chanErr:
		mylog.Error("Start Server error", `err`, err.Error())
		return err
	case <-time.After(time.Millisecond * 256):
		mylog.Info("StartServer success", `port`, port)
		return nil
	}
}

// ShareClosed .
func (s *Server) ShareClosed() {
	s.mux.Lock()
	defer s.mux.Unlock()
	if s.shareListener != nil {
		_ = s.shareListener.Close()
	}
}
