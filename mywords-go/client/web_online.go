package client

//#include <stdlib.h>
import "C"
import (
	"fmt"
	"io"
	"mywords/pkg/log"
	"mywords/pkg/util"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"time"
)

func (c *Client) StartWebOnline(webPort int64, fileSystem http.FileSystem, serverHTTPCallFunc func(w http.ResponseWriter, r *http.Request)) error {
	c.serverHTTPCallFunc = serverHTTPCallFunc
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", webPort))
	if err != nil {
		log.Ctx(ctx).Error(err.Error())
		lis, err = net.Listen("tcp", fmt.Sprintf(":%d", 0))
		if err != nil {
			return err
		}
	}
	log.Printf("online web dict running: %s", lis.Addr().String())
	rootDir := c.rootDataDir
	if checkRunning(rootDir) {
		log.Println("WARNING: the process already exists, please kill it first and running one instance at the same time")
	}
	//initGlobal(*rootDir, *dictPort)
	mux := http.NewServeMux()
	mux.HandleFunc("/call/", func(writer http.ResponseWriter, request *http.Request) {
		if c.GetWebOnlineClose() {
			writer.WriteHeader(http.StatusForbidden)
			return
		}
		c.serverHTTPCallFunc(writer, request)
	})
	mux.HandleFunc("/_addDictWithFile", func(writer http.ResponseWriter, request *http.Request) {
		if c.GetWebOnlineClose() {
			writer.WriteHeader(http.StatusForbidden)
			return
		}
		c.addDictWithChunkedFile(writer, request)
	})
	fileServer := http.FileServer(fileSystem)
	mux.HandleFunc("/web/", func(writer http.ResponseWriter, request *http.Request) {
		if c.GetWebOnlineClose() {
			writer.WriteHeader(http.StatusForbidden)
			return
		}
		fileServer.ServeHTTP(writer, request)
	})
	tcpAddr, err := net.ResolveTCPAddr("tcp", lis.Addr().String())
	if err != nil {
		return err
	}
	webOnlinePort := tcpAddr.Port
	c.webOnlinePort = webOnlinePort
	log.Ctx(ctx).Info(os.Getwd())
	go func() {
		openBrowser(fmt.Sprintf("http://127.0.0.1:%d/web/", webOnlinePort))
	}()
	if err = http.Serve(lis, mux); err != nil {
		log.Println(err)
		return err
	}
	return nil
}

func (c *Client) addDictWithChunkedFile(w http.ResponseWriter, r *http.Request) {
	if util.CORS(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()
	accumulativeSize, err := strconv.ParseInt(r.URL.Query().Get("accumulative"), 10, 64)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	fileSize, err := strconv.ParseInt(r.URL.Query().Get("fileSize"), 10, 64)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fileUniqueId := r.URL.Query().Get("fileUniqueId")
	name := r.URL.Query().Get("name")
	seq := r.URL.Query().Get("seq")
	// todo check seq, seq must be a number
	// TODO 启动时候删除temp
	tempPath := filepath.Join(homeDir, ".cache", "mywords", "temp", fileUniqueId)
	err = os.MkdirAll(tempPath, os.ModePerm)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	tempFile := filepath.Join(tempPath, seq)
	f, err := os.Create(tempFile)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	_, err = io.Copy(f, r.Body)
	if err != nil {
		log.Ctx(ctx).Errorf("copy file error: %v", err)
		_ = f.Close()
		_ = os.Remove(tempFile)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	err = f.Close()
	if err != nil {
		log.Ctx(ctx).Errorf("close file error: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if accumulativeSize >= fileSize {
		log.Println("merge----------------------")
		err = c.mergeChunkedToDict(tempPath, name)
		if err != nil {
			log.Ctx(ctx).Errorf("mergeChunkedToDict   error: %v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}
}
func (c *Client) mergeChunkedToDict(tempPath string, name string) error {
	defer os.RemoveAll(tempPath)
	zipPath := filepath.Join(tempPath, fmt.Sprintf("%d.zip", time.Now().UnixNano()))
	fw, err := os.Create(zipPath)
	if err != nil {
		return err
	}
	defer fw.Close()
	for i := 1; true; i++ {
		fPath := filepath.Join(tempPath, fmt.Sprintf("%d", i))
		f, err := os.Open(fPath)
		if err != nil {
			break
		}
		n, err := io.Copy(fw, f)
		if err != nil {
			f.Close()
			return err
		}
		log.Printf("mergeChunkedToDict %d: zipPath:%s, name: %s,n:%d", i, zipPath, name, n)
		f.Close()
	}
	if err = fw.Close(); err != nil {
		return err
	}
	err = c.AddDictWithName(ctx, zipPath, name)
	if err != nil {
		log.Ctx(ctx).Errorf("add dict error: %v", err)
		return err
	}
	return nil
}

func openBrowser(url string) {
	var err error
	switch runtime.GOOS {
	case "windows":
		err = exec.Command("cmd", "/c start "+url).Run()
	case "darwin":
		err = exec.Command("open", url).Run()
	case "android", "ios":
	case "linux":
		err = exec.Command("xdg-open", url).Run()
	default:
	}
	if err != nil {
		fmt.Printf("open url error: %s\n", url)
		return
	}
	fmt.Printf("open %s in your browser\n", url)
}
