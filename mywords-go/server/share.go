package server

import (
	"fmt"
	"io"
	"mywords/mylog"
	"mywords/util"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

func (s *Server) serverHTTPShareBackUpData(w http.ResponseWriter, r *http.Request) {
	srcDataPath := filepath.Join(s.rootDataDir, dataDir)
	remoteHost, _, _ := net.SplitHostPort(r.RemoteAddr)
	if remoteHost == "" {
		remoteHost = r.RemoteAddr
	}
	mylog.Info("share data begin", "remoteHost", remoteHost)
	// download when it's false
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename=%s`, "mywords-backupdata.zip"))
	err := util.ZipToWriter(w, srcDataPath)
	if err != nil {
		mylog.Error("share data error", "remoteHost", remoteHost, "err", err.Error())
		w.WriteHeader(500)
		w.Write([]byte(err.Error()))
	}
	mylog.Info("share data done", "remoteHost", remoteHost)
}

// RestoreFromShareServer . restore from a zip file
func (s *Server) RestoreFromShareServer(ip string, port int, code int64, tempDir string, syncToadyWordCount bool) error {
	httpUrl := fmt.Sprintf("http://%s:%d/%d", ip, port, code)
	// save to temp dir
	tempZipPath := filepath.Join(tempDir, fmt.Sprintf("mywors-%d.zip", time.Now().UnixMilli()))
	err := download(httpUrl, tempZipPath)
	if err != nil {
		return err
	}
	// defer delete temp file
	defer func() {
		_ = os.Remove(tempZipPath)
	}()
	err = s.restoreFromBackUpData(tempZipPath, syncToadyWordCount)
	if err != nil {
		return err
	}
	return nil
}
func download(httpUrl string, tempZipPath string) (err error) {
	resp, err := http.Get(httpUrl)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		mylog.Error("download error", "httpUrl", httpUrl, "statusCode", resp.StatusCode)
		return fmt.Errorf("http status code %d", resp.StatusCode)
	}
	f, err := os.Create(tempZipPath)
	if err != nil {
		return err
	}
	defer func() {
		err = f.Close()
	}()
	_, err = io.Copy(f, resp.Body)
	if err != nil {
		return err
	}
	return nil
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
