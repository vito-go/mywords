package main

import "C"
import "mywords/dict"

//export GetUrlByWordForWeb
func GetUrlByWordForWeb(hostnameC *C.char, wordC *C.char) *C.char {
	u, _ := serverGlobal.GetUrlByWord(C.GoString(hostnameC), C.GoString(wordC))
	return CharOk(u)
}

//export ExistInDict
func ExistInDict(wordC *C.char) bool {
	return serverGlobal.OneDict().ExistInDict(C.GoString(wordC))
}

//export GetDefaultDictId
func GetDefaultDictId() int64 {
	u := serverGlobal.DefaultDictId()
	return u
}

//export DelDict
func DelDict(id int64) *C.char {
	u := serverGlobal.DelDict(ctx, id)
	return CharOk(u)
}

//export UpdateDictName
func UpdateDictName(id int64, nameC *C.char) *C.char {
	err := serverGlobal.AllDao().DictInfoDao.UpdateNameById(ctx, id, C.GoString(nameC))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export SetDefaultDict
func SetDefaultDict(id int64) *C.char {
	err := serverGlobal.SetDefaultDictById(ctx, id)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export DictList
func DictList() *C.char {
	items, err := serverGlobal.AllDao().DictInfoDao.AllItems(ctx)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(items)
}

//export AddDict
func AddDict(zipFileC *C.char) *C.char {
	err := serverGlobal.AddDict(ctx, C.GoString(zipFileC))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export CheckDictZipTargetPathExist
func CheckDictZipTargetPathExist(zipPathC *C.char) bool {
	_, exist, _ := serverGlobal.GetTargetPathAndCheckExist(C.GoString(zipPathC))
	return exist
}

//export SearchByKeyWord
func SearchByKeyWord(keyWordC *C.char) *C.char {
	if serverGlobal.DefaultDictId() == 0 {
		items := dict.SearchByKeyWord(C.GoString(keyWordC), dict.DefaultDictWordMap)
		return CharOk(items)
	}
	items := serverGlobal.OneDict().SearchByKeyWord(C.GoString(keyWordC))
	return CharOk(items)
}

//export GetHTMLRenderContentByWord
func GetHTMLRenderContentByWord(wordC *C.char) *C.char {
	p, err := serverGlobal.OneDict().GetHTMLRenderContentByWord(C.GoString(wordC))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(p)
}
