package main

import "C"
import (
	"mywords/dict"
	"sort"
)

var multiDictGlobal *dict.MultiDict

//export GetUrlByWord
func GetUrlByWord(wordC *C.char) *C.char {
	u, _ := multiDictGlobal.GetUrlByWord(C.GoString(wordC))
	return CharOk(u)
}

//export FinalHtmlBasePathWithOutHtml
func FinalHtmlBasePathWithOutHtml(wordC *C.char) *C.char {
	u, _ := multiDictGlobal.FinalHtmlBasePathWithOutHtml(C.GoString(wordC))
	return CharOk(u)
}

//export GetDefaultDict
func GetDefaultDict() *C.char {
	u := multiDictGlobal.GetDefaultDict()
	return CharOk(u)
}

//export DelDict
func DelDict(basePath *C.char) *C.char {
	u := multiDictGlobal.DelDict(C.GoString(basePath))
	return CharOk(u)
}

//export UpdateDictName
func UpdateDictName(dataDirC, nameC *C.char) *C.char {
	err := multiDictGlobal.UpdateDictName(C.GoString(dataDirC), C.GoString(nameC))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export SetDefaultDict
func SetDefaultDict(dataDirC *C.char) *C.char {
	err := multiDictGlobal.SetDefaultDict(C.GoString(dataDirC))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export DictList
func DictList() *C.char {
	m := multiDictGlobal.DictBasePathTitleMap()
	type t struct {
		BasePath string `json:"basePath,omitempty"`
		Title    string `json:"title,omitempty"`
	}
	var result []t
	for zipFile, name := range m {
		result = append(result, t{
			BasePath: zipFile,
			Title:    name,
		})
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].BasePath < result[j].BasePath
	})
	return CharOk(result)
}

//export AddDict
func AddDict(zipFileC *C.char) *C.char {
	err := multiDictGlobal.AddDict(C.GoString(zipFileC))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export SearchByKeyWord
func SearchByKeyWord(keyWordC *C.char) *C.char {
	items := multiDictGlobal.SearchByKeyWord(C.GoString(keyWordC))
	return CharOk(items)
}

//export GetHTMLRenderContentByWord
func GetHTMLRenderContentByWord(wordC *C.char) *C.char {
	p, err := multiDictGlobal.GetHTMLRenderContentByWord(C.GoString(wordC))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(p)
}
