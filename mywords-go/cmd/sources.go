package main

import "C"
import (
	"encoding/json"
	"strings"
)

//export GetAllSources
func GetAllSources() *C.char {
	allSources := serverGlobal.GetAllSources(ctx)
	return CharList(allSources)
}

//export RefreshPublicSources
func RefreshPublicSources() *C.char {
	err := serverGlobal.RefreshPublicSources(ctx)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export AddSourcesToDB
func AddSourcesToDB(sourcesC *C.char) *C.char {
	var sources []string
	ss := strings.Split(C.GoString(sourcesC), "\n")
	for _, s := range ss {
		// 去掉首尾空格以及逗号
		s = strings.TrimSpace(s)
		s = strings.Trim(s, ",")
		sources = append(sources, s)
	}
	err := serverGlobal.AddSourcesToDB(ctx, sources)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export DeleteSourcesFromDB
func DeleteSourcesFromDB(sourcesC *C.char) *C.char {
	var sources []string
	err := json.Unmarshal([]byte(C.GoString(sourcesC)), &sources)
	if err != nil {
		return CharErr(err.Error())
	}
	err = serverGlobal.DeleteSourcesFromDB(ctx, sources)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export AllSourcesFromDB
func AllSourcesFromDB() *C.char {
	sourcesPrivate, _ := serverGlobal.AllDao().Sources.AllItems(ctx)
	var sources []string
	for _, source := range sourcesPrivate {
		sources = append(sources, source.Source)
	}
	return CharList(sources)
}
