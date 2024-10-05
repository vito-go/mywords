package main

import "C"
import "encoding/json"

type CBody[T any] struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    T      `json:"data"` // 不要用omitempty,因为可能返回一个空字符串
}

type defaultNullType = map[string]interface{}

func CharErr(errMsg string) *C.char {
	result, _ := json.Marshal(&CBody[defaultNullType]{
		Code:    10000,
		Message: errMsg,
	})
	return C.CString(string(result))
}
func CharOk[T any](data T) *C.char {
	result, _ := json.Marshal(&CBody[T]{
		Code:    0,
		Message: "success",
		Data:    data,
	})
	return C.CString(string(result))
}
func CharList[T string | int](data []T) *C.char {
	result, _ := json.Marshal(data)
	return C.CString(string(result))
}

// CharMap .
func CharMap[K string | int | int64, T any](data map[K]T) *C.char {
	result, _ := json.Marshal(data)
	return C.CString(string(result))
}

func CharSuccess() *C.char {
	result, _ := json.Marshal(&CBody[defaultNullType]{
		Code:    0,
		Message: "success",
	})
	return C.CString(string(result))
}
