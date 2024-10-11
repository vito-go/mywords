package main

//#include <stdlib.h>
import "C"
import (
	"encoding/json"
	"fmt"
	"io"
	"mywords/pkg/log"
	"mywords/pkg/util"
	"net/http"
	"reflect"
	"strings"
	"unsafe"
)

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
	waitFreeC := make([]*C.char, 0, len(args))
	defer func() {
		for i := range waitFreeC {
			C.free(unsafe.Pointer(waitFreeC[i]))
		}
	}()
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
				waitFreeC = append(waitFreeC, argC)
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
				waitFreeC = append(waitFreeC, argC)
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

func serverHTTPCallFunc(w http.ResponseWriter, r *http.Request) {
	if util.CORS(w, r) {
		return
	}
	defer r.Body.Close()
	funcName := strings.TrimPrefix(r.URL.Path, "/call/")
	if funcName == "" {
		http.Error(w, "Please send a functionName", http.StatusBadRequest)
		return
	}
	if err := serverHTTPCallFuncLocalCheck(funcName, r); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	var args []interface{}
	err := json.NewDecoder(r.Body).Decode(&args)
	// When the method is GET, the body is empty, so the error is io.EOF
	if err != nil && err != io.EOF {
		http.Error(w, err.Error(), http.StatusBadRequest)
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
		http.Error(w, fmt.Sprintf("Function return type not support: %T, value: %+v", v, v), http.StatusInternalServerError)
	}
}

// 敏感操作只允许本地调用
func serverHTTPCallFuncLocalCheck(funcName string, r *http.Request) error {
	if !sensitiveFunMap[funcName] {
		return nil
	}
	//[::1]:55518
	if !strings.HasPrefix(r.RemoteAddr, "[::1]") && !strings.HasPrefix(r.RemoteAddr, "127.0.0.1") && !strings.HasPrefix(r.RemoteAddr, "localhost") {
		return fmt.Errorf("sensitive function only allow local call")
	}
	return nil
}
