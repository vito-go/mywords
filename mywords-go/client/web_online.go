package client

//#include <stdlib.h>
import "C"
import (
	"encoding/json"
	"fmt"
	"io"
	"mywords/pkg/log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"runtime"
	"strconv"
	"strings"
	"time"
	"unsafe"
)

func (c *Client) StartWebOnline(webPort int64, fileSystem http.FileSystem, m ExportedFuncMap) error {
	c.exportedFuncMap = m
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", webPort))
	if err != nil {
		lis, err = net.Listen("tcp", fmt.Sprintf(":%d", 0))
		if err != nil {
			return err
		}
	}
	log.Println("online web dict running: %s", lis.Addr().String())
	rootDir := c.rootDataDir
	if checkRunning(rootDir) {
		log.Println("WARNING: the process %d already exists, please kill it first and running one instance at the same time")
	}
	//initGlobal(*rootDir, *dictPort)
	mux := http.NewServeMux()
	mux.HandleFunc("/call/", func(writer http.ResponseWriter, request *http.Request) {
		if c.webOnlineClose.Load() {
			writer.WriteHeader(http.StatusForbidden)
			return
		}
		c.serverHTTPCallFunc(writer, request)
	})
	mux.HandleFunc("/_addDictWithFile", func(writer http.ResponseWriter, request *http.Request) {
		if c.webOnlineClose.Load() {
			writer.WriteHeader(http.StatusForbidden)
			return
		}
		c.addDictWithChunkedFile(writer, request)
	})
	fileServer := http.FileServer(fileSystem)
	mux.HandleFunc("/", func(writer http.ResponseWriter, request *http.Request) {
		if c.webOnlineClose.Load() {
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
		openBrowser(fmt.Sprintf("http://127.0.0.1:%d", webOnlinePort))
	}()
	if err = http.Serve(lis, mux); err != nil {
		log.Println(err)
		return err
	}
	return nil
}

//          "name": name,
//          "seq": seq,
//          "fileSize": fileSize,
//          "fileUniqueId": fileUniqueId

func (c *Client) addDictWithChunkedFile(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
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

func cors(w http.ResponseWriter, r *http.Request) (aborted bool) {
	origin := r.Header.Get("origin")
	w.Header().Set("Access-Control-Allow-Origin", origin)
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Allow-Methods", "OPTIONS,POST,GET")
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return true
	}
	return false
}

func (c *Client) serverHTTPCallFunc(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
		return
	}
	defer r.Body.Close()
	var args []interface{}
	err := json.NewDecoder(r.Body).Decode(&args)
	// When the method is GET, the body is empty, so the error is io.EOF
	if err != nil && err != io.EOF {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	funcName := strings.TrimPrefix(r.URL.Path, "/call/")
	if funcName == "" {
		http.Error(w, "Please send a functionName", http.StatusBadRequest)
		return
	}
	log.Println("call function", "funcName", funcName, "remoteAddr", r.RemoteAddr, "method", r.Method)
	fn, ok := c.exportedFuncMap[funcName]
	if !ok {
		http.Error(w, "Function not found: "+funcName, http.StatusNotFound)
		return
	}
	response, err := call(fn, args)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if len(response) == 0 {
		//http.Error(w, "Function return nothing", http.StatusInternalServerError)
		return
	}
	if len(response) == 1 {
		v := response[0]
		k := v.Kind()
		switch k {
		case reflect.Chan, reflect.Func, reflect.Map, reflect.Pointer, reflect.UnsafePointer:
		case reflect.Interface, reflect.Slice:
		default:
			// return only one value, without json
			w.Write([]byte(fmt.Sprintf("%v", v)))
			return
		}
		if response[0].IsNil() {
			http.Error(w, "Function return nil", http.StatusInternalServerError)
			return
		}
	}
	value := response[0].Interface()
	// 判断 value 的类型，支持 string, []byte, *C.char 类型, 其他类型请先转换为这三种类型之一，例如struct类型转换为json字符串
	// application/json
	w.Header().Set("Content-Type", "application/json")
	switch v := value.(type) {
	case string:
		w.Write([]byte(v))
	case []byte:
		w.Write(v)
	case *C.char:
		defer C.free(unsafe.Pointer(v))
		w.Write([]byte(C.GoString(v)))
	default:
		http.Error(w, fmt.Sprintf("Function return type not support: %T", v), http.StatusInternalServerError)
	}
}
func openBrowser(url string) {
	var err error
	switch runtime.GOOS {
	case "windows":
		err = exec.Command("cmd", "/c start "+url).Run()
	case "darwin":
		err = exec.Command("open", url).Run()
	default:
		err = exec.Command("xdg-open", url).Run()
	}
	if err != nil {
		fmt.Printf("open url error: %s\n", url)
	}
	fmt.Printf("open %s in your browser\n", url)
}
