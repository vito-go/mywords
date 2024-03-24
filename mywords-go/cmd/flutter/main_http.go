//go:build !flutter

package main

//#include <stdlib.h>
import "C"
import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"mywords/util"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"
	"time"
	"unsafe"
)

func main() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	defaultRootDir := filepath.Join(homeDir, ".local/share/com.example.mywords")
	port := flag.Int("port", 18960, "http server port")
	rootDataDir := flag.String("rootDataDir", defaultRootDir, "root data dir")
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		panic(err)
	}
	initGlobal(*rootDataDir)
	mux := http.NewServeMux()
	mux.HandleFunc("/call/", serverHTTPCallFunc)
	mux.HandleFunc("/_addDictWithFile", addDictWithFile)
	mux.HandleFunc("/_downloadBackUpdate", downloadBackUpdate)
	mux.HandleFunc("/_webParseAndSaveArticleFromFile", webParseAndSaveArticleFromFile)
	log.Println("server start", *port)
	if err = http.Serve(lis, mux); err != nil {
		panic(err)
	}
}

// 通过反射调用flutter的API funcName: 方法名  args: 参数
// function: 要调用的函数,参数类型支持float64，int，int64, string, bool,C*char 类型
// args: 调用函数的参数，参数类型支持float64，int，int64, string, bool类型
func call(function any, args []interface{}) (response []reflect.Value, err error) {
	//defer func() {
	//	if e := recover(); e != nil {
	//		response = nil
	//		err = fmt.Errorf("%v", e)
	//	}
	//}()
	f := reflect.ValueOf(function)
	if f.Kind() != reflect.Func {
		return nil, fmt.Errorf("not a function")
	}
	numIn := f.Type().NumIn()
	if len(args) != numIn {
		return nil, fmt.Errorf("args length not match, expect %d, but got %d", numIn, len(args))
	}
	argValues := make([]reflect.Value, numIn)
	for i, arg := range args {
		var newValue reflect.Value
		k := f.Type().In(i).Kind()
		switch v := arg.(type) {
		case int, int32, int64, float64:
			// 改写为switch
			switch k {
			case reflect.Float64:
				switch v.(type) {
				case int:
					newValue = reflect.ValueOf(float64(v.(int)))
				case int32:
					newValue = reflect.ValueOf(float64(v.(int32)))
				case int64:
					newValue = reflect.ValueOf(float64(v.(int64)))
				case float64:
					newValue = reflect.ValueOf(v.(float64))
				}
			case reflect.Int:
				switch v.(type) {
				case int:
					newValue = reflect.ValueOf(v.(int))
				case int32:
					newValue = reflect.ValueOf(int(v.(int32)))
				case int64:
					newValue = reflect.ValueOf(int(v.(int64)))
				case float64:
					newValue = reflect.ValueOf(int(v.(float64)))
				}

			case reflect.Int64:
				switch v.(type) {
				case int:
					newValue = reflect.ValueOf(int64(v.(int)))
				case int32:
					newValue = reflect.ValueOf(int64(v.(int32)))
				case int64:
					newValue = reflect.ValueOf(v.(int64))
				case float64:
					newValue = reflect.ValueOf(int64(v.(float64)))
				}
			default:
				return nil, fmt.Errorf("args type not match,[%d] expect %v, but got %v", i, k, reflect.Float64)
			}
		case string:
			// 改写为switch
			switch k {
			case reflect.String:
				newValue = reflect.ValueOf(v)
			case reflect.Ptr:
				argC := C.CString(v)
				defer C.free(unsafe.Pointer(argC))
				newValue = reflect.ValueOf(argC)
			default:
				return nil, fmt.Errorf("args type not match,[%d] expect %v, but got %v", i, k, reflect.String)
			}

		case []interface{}, map[string]interface{}:
			b, _ := json.Marshal(v)
			s := string(b)
			// 改写为switch
			switch k {
			case reflect.String:
				newValue = reflect.ValueOf(s)
			case reflect.Ptr:
				argC := C.CString(s)
				defer C.free(unsafe.Pointer(argC))
				newValue = reflect.ValueOf(argC)
			default:
				return nil, fmt.Errorf("args type not match,[%d] expect %v, but got %v", i, k, reflect.String)
			}
		case bool:
			if k != reflect.Bool {
				return nil, fmt.Errorf("args type not match,[%d] expect %v, but got %v", i, k, reflect.Bool)
			}
			newValue = reflect.ValueOf(v)
		default:
			return nil, fmt.Errorf("args type not support [%d] %v", i, k)
		}

		argValues[i] = newValue
	}
	return f.Call(argValues), nil
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
	//defer mylog.Ctx(r.Context()).WithFields("remoteAddr", r.RemoteAddr, "method", r.Method, "path", path).Info("====")
	// app端暂不需考虑支持跨域
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
	if err := json.NewDecoder(r.Body).Decode(&args); err != nil && err != io.EOF {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	funcName := strings.TrimPrefix(r.URL.Path, "/call/")
	if funcName == "" {
		http.Error(w, "Please send a functionName", http.StatusBadRequest)
		return
	}
	log.Println(r.RemoteAddr, r.Method, funcName)

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
