package main

//#include <stdlib.h>
import "C"
import (
	"encoding/json"
	"fmt"
	"io"
	"mywords/pkg/log"
	"reflect"

	"mywords/pkg/util"
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
	size, err := io.Copy(f, r.Body)
	_ = size
	if err != nil {
		_ = f.Close()
		_ = os.Remove(tempFile)
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
		http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
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
	_, err = io.Copy(f, r.Body)
	if err != nil {
		_ = f.Close()
		_ = os.Remove(tempFile)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	f.Close()
	// delete file
	defer os.Remove(tempFile)
	_, err = serverGlobal.ParseAndSaveArticleFromFile(tempFile)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

//          "name": name,
//          "seq": seq,
//          "fileSize": fileSize,
//          "fileUniqueId": fileUniqueId

func addDictWithFileMany(w http.ResponseWriter, r *http.Request) {
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

	if accumulativeSize == fileSize {
		log.Println("merge----------------------")
		err = mergeToDict(tempPath, name)
		if err != nil {
			log.Ctx(ctx).Errorf("mergeToDict   error: %v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}
}
func mergeToDict(tempPath string, name string) error {
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
		log.Printf("mergeToDict %d: zipPath:%s, name: %s,n:%d", i, zipPath, name, n)
		f.Close()
	}
	if err = fw.Close(); err != nil {
		return err
	}
	err = serverGlobal.AddDictWithName(ctx, zipPath, name)
	if err != nil {
		log.Ctx(ctx).Errorf("add dict error: %v", err)
		return err
	}
	return nil
}

func addDictWithFile(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()
	homeDir, err := os.UserHomeDir()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
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
	defer os.Remove(tempFile)
	err = serverGlobal.AddDict(ctx, tempFile)
	if err != nil {
		log.Ctx(ctx).Errorf("add dict error: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}
func addDictWithFileWithFormData(w http.ResponseWriter, r *http.Request) {
	if cors(w, r) {
		return
	}
	err := r.ParseMultipartForm(64 << 20)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()
	homeDir, err := os.UserHomeDir()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	tempPath := filepath.Join(homeDir, ".cache", "mywords")
	os.MkdirAll(tempPath, os.ModePerm)
	fileName := r.URL.Query().Get("name")
	tempFile := filepath.Join(tempPath, fileName)
	f, err := os.Create(tempFile)
	log.Ctx(ctx).Infof("create file: %s", tempFile)
	if err != nil {
		log.Ctx(ctx).Errorf("create file error: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer r.MultipartForm.RemoveAll()
	files := r.MultipartForm.File["file"]
	if len(files) == 0 {
		http.Error(w, "file not found", http.StatusBadRequest)
		return
	}
	file := files[0]
	fOpen, err := file.Open()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer fOpen.Close()
	log.Printf("ready to copy,file: %s, fileSize: %d, Filename:%s", tempFile, file.Size, file.Filename)
	_, err = io.Copy(f, fOpen)
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
	defer os.Remove(tempFile)
	err = serverGlobal.AddDict(ctx, tempFile)
	if err != nil {
		log.Ctx(ctx).Errorf("add dict error: %v", err)
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
		http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
		return
	}
	fileName := r.URL.Query().Get("name") // e.g. "backupdate.zip"
	// can not include ".." and "/"
	if strings.Contains(fileName, "..") || strings.Contains(fileName, "/") {
		http.Error(w, "Invalid file name", http.StatusBadRequest)
		return
	}
	srcDataPath := serverGlobal.DataDir()
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
