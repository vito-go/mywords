//go:build !flutter

package main

//#include <stdlib.h>
import "C"
import (
	"embed"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"mywords/mylog"
	"mywords/util"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
	"unsafe"
)

// 请把flutter build web的文件放到web目录下 否则编译不通过 pattern web/*: no matching files found
//
//go:embed web/*
var webEmbed embed.FS

func main() {

	defaultRootDir, err := getApplicationDir()
	if err != nil {
		panic(err)
	}
	port := flag.Int("port", 18960, "http server port")
	dictPort := flag.Int("dictPort", 18961, "dict port")
	embeded := flag.Bool("embed", true, "embedded web")
	rootDir := flag.String("rootDir", defaultRootDir, "root dir")
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		panic(err)
	}
	initGlobal(*rootDir, *dictPort)
	mux := http.NewServeMux()
	mux.HandleFunc("/call/", serverHTTPCallFunc)
	mux.HandleFunc("/_addDictWithFile", addDictWithFile)
	mux.HandleFunc("/_downloadBackUpdate", downloadBackUpdate)
	mux.HandleFunc("/_webParseAndSaveArticleFromFile", webParseAndSaveArticleFromFile)
	mux.HandleFunc("/_webRestoreFromBackUpData", webRestoreFromBackUpData)

	if *embeded {
		// 请把flutter build web的文件放到web目录下
		mux.Handle("/", http.FileServer(http.FS(&webEmbedHandler{webEmbed: webEmbed})))
	} else {
		// 本地开发时，使用flutter web的文件, 请不要在生产环境使用，以防build/web目录被删除, 例如flutter clean
		_, file, _, ok := runtime.Caller(0)
		if ok {
			dir := filepath.ToSlash(filepath.Join(filepath.Dir(file), "../../../mywords-flutter/build/web"))
			mylog.Info("embedded false", "dir", dir)
			mux.Handle("/", http.FileServer(http.Dir(dir)))
		} else {
			panic("runtime.Caller failed")
		}
	}
	mylog.Info("server start", "port", *port, "rootDir", *rootDir)
	go func() {
		time.Sleep(time.Second)
		openBrowser(fmt.Sprintf("http://localhost:%d", *port))
	}()
	if err = http.Serve(lis, mux); err != nil {
		panic(err)
	}
}

func webRestoreFromBackUpData(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()
	syncKnownWords := r.URL.Query().Get("syncKnownWords") == "true"
	syncToadyWordCount := r.URL.Query().Get("syncToadyWordCount") == "true"
	syncByRemoteArchived := r.URL.Query().Get("syncByRemoteArchived") == "true"
	name := "mywords-backupdate.zip"
	tempFile := filepath.Join(os.TempDir(), name)
	f, err := os.Create(tempFile)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer f.Close()
	size, err := io.Copy(f, r.Body)
	_ = size
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	// 保存文件
	f.Close()
	// delete file
	defer os.Remove(tempFile)
	err = serverGlobal.RestoreFromBackUpData(syncKnownWords, tempFile, syncToadyWordCount, syncByRemoteArchived)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}
func webParseAndSaveArticleFromFile(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()
	name := r.URL.Query().Get("name")
	if name == "" {
		http.Error(w, "Please send a name", http.StatusBadRequest)
		return

	}
	tempFile := filepath.Join(os.TempDir(), name)
	f, err := os.Create(tempFile)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer f.Close()
	_, err = io.Copy(f, r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	// 保存文件
	f.Close()
	// delete file
	defer os.Remove(tempFile)
	_, err = serverGlobal.ParseAndSaveArticleFromFile(tempFile)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func addDictWithFile(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()
	homeDir, err := os.UserHomeDir()
	if err != nil {
		http.Error(w, "Function return nothing", http.StatusInternalServerError)
		return
	}
	tempPath := filepath.Join(homeDir, ".cache", "mywords")
	os.MkdirAll(tempPath, os.ModePerm)
	fileName := r.URL.Query().Get("name")
	tempFile := filepath.Join(tempPath, fileName)
	f, err := os.Create(tempFile)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer f.Close()
	_, err = io.Copy(f, r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	// 保存文件
	f.Close()
	// delete file
	defer os.Remove(tempFile)
	err = multiDictGlobal.AddDict(tempFile)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// cors 通用的跨域处理
func cors(w http.ResponseWriter, r *http.Request) bool {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Allow-Methods", "*")
	if r.Method == http.MethodOptions {
		w.Header().Set("Access-Control-Max-Age", strconv.FormatInt(int64(time.Second*60*60*24*3), 10))
		return true
	}
	return false
}

func downloadBackUpdate(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
		return
	}
	// 通过反射调用flutter的API post 请求 /call/functionName= body: []interface{}
	if r.Method != http.MethodGet {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}
	fileName := r.URL.Query().Get("name") // e.g. "backupdate.zip"
	// can not include ".." and "/"
	if strings.Contains(fileName, "..") || strings.Contains(fileName, "/") {
		http.Error(w, "Invalid file name", http.StatusBadRequest)
		return
	}
	srcDataPath := serverGlobal.ZipDataDir()
	// download header
	w.Header().Set("Content-Type", "application/zip")
	w.Header().Set("Content-Disposition", "attachment; filename="+fileName)
	// zip
	err := util.ZipToWriter(w, srcDataPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func serverHTTPCallFunc(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
		return
	}
	// 通过反射调用flutter的API post 请求 /call/functionName= body: []interface{}
	//if r.Method != http.MethodPost {
	//	http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
	//	return
	//}
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
	mylog.Info("call function", "funcName", funcName, "remoteAddr", r.RemoteAddr, "method", r.Method)
	fn, ok := exportedFuncMap[funcName]
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
		http.Error(w, "Function return nothing", http.StatusInternalServerError)
		return
	}
	if len(response) == 1 {
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
func getApplicationDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	defaultRootDir := filepath.Join(homeDir, ".local/share/com.example.mywords")
	switch runtime.GOOS {
	case "windows":
		defaultRootDir = filepath.Join(homeDir, "AppData/Roaming/com.example/mywords")
	case "darwin":
		defaultRootDir = filepath.Join(homeDir, "Library/Application Support/com.example.mywords")
	case "linux":
		defaultRootDir = filepath.Join(homeDir, ".local/share/com.example.mywords")
	}
	// 请注意，如果同时打开多个应用，可能会导致目录冲突，数据造成不一致或丢失
	defaultRootDir = filepath.ToSlash(defaultRootDir)
	return defaultRootDir, err
}
