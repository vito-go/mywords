package main

//#include <stdlib.h>
import "C"
import (
	"encoding/json"
	"fmt"
	"reflect"
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
