package main

import "C"
import (
	"context"
	"encoding/json"
	"mywords/artical"
	"mywords/client"
	"mywords/dict"
	"mywords/model"
	"mywords/model/mtype"
	"mywords/pkg/util"
	"net"
	"sort"
	"strings"
)

var serverGlobal *client.Client

//export UpdateKnownWordLevel
func UpdateKnownWordLevel(c *C.char, level int) *C.char {
	word := C.GoString(c)
	err := serverGlobal.AllDao().KnownWordsDao.UpdateOrCreate(ctx, word, mtype.WordKnownLevel(level))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export ShareOpen
func ShareOpen(port int, code int64) *C.char {
	err := serverGlobal.ShareOpen(port, code)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export GetShareInfo
func GetShareInfo() *C.char {
	info := serverGlobal.GetShareInfo()
	return CharOk(info)
}

//export GetChartData
func GetChartData() *C.char {
	data, err := serverGlobal.GetChartData()
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(data)
}

//export GetChartDataAccumulate
func GetChartDataAccumulate() *C.char {
	data, err := serverGlobal.GetChartDataAccumulate()
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(data)
}

//export AllKnownWordMap
func AllKnownWordMap() *C.char {
	data := serverGlobal.AllKnownWordMap()
	return CharOk(data)
}

//export TodayKnownWordMap
func TodayKnownWordMap() *C.char {
	data := serverGlobal.TodayKnownWordMap()
	return CharOk(data)
}

//export GetToadyChartDateLevelCountMap
func GetToadyChartDateLevelCountMap() *C.char {
	data := serverGlobal.GetToadyChartDateLevelCountMap()
	return CharOk(data)
}

//export ShareClosed
func ShareClosed() *C.char {
	serverGlobal.ShareClosed()
	return CharSuccess()
}

//export NewArticleFileInfoBySourceURL
func NewArticleFileInfoBySourceURL(sourceUrl *C.char) *C.char {
	art, err := serverGlobal.NewArticleFileInfoBySourceURL(C.GoString(sourceUrl))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(art)
}

//export RenewArticleFileInfo
func RenewArticleFileInfo(id int64) *C.char {
	art, err := serverGlobal.RenewArticleFileInfo(id)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(art)
}

//export ReparseArticleFileInfo
func ReparseArticleFileInfo(id int64) *C.char {
	art, err := serverGlobal.ReparseArticleFileInfo(id)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(art)
}

//export RestoreFromBackUpData
func RestoreFromBackUpData(syncKnownWords bool, zipFile *C.char, syncToadyWordCount, syncByRemoteArchived bool) *C.char {
	err := serverGlobal.RestoreFromBackUpData(syncKnownWords, C.GoString(zipFile), syncToadyWordCount, syncByRemoteArchived)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export BackUpData
func BackUpData(targetZipPathC *C.char, srcDataPathC *C.char) *C.char {
	targetZipPath, srcDataPath := C.GoString(targetZipPathC), C.GoString(srcDataPathC)
	err := util.Zip(targetZipPath, srcDataPath)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export DictWordQuery
func DictWordQuery(wordC *C.char) *C.char {
	key := C.GoString(wordC)
	s, ok := dict.DefaultDictWordMap[key]
	if ok {
		return CharOk(s)
	}
	s = dict.DefaultDictWordMap[strings.ToLower(key)]
	return CharOk(s)
}

//export DictWordQueryLink
func DictWordQueryLink(wordC *C.char) *C.char {
	key := C.GoString(wordC)
	s, ok := dict.WordLinkMap[key]
	if ok {
		return CharOk(s)
	}
	s = dict.WordLinkMap[strings.ToLower(key)]
	return CharOk(s)
}

var ctx = context.TODO()

//export KnownWordsCountMap
func KnownWordsCountMap() *C.char {
	var m, err = serverGlobal.AllDao().KnownWordsDao.LevelWordsCountMap(ctx)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(m)
}

//export ParseVersion
func ParseVersion() *C.char {
	return CharOk(artical.ParseVersion)
}

//export ProxyURL
func ProxyURL() *C.char {
	return CharOk(serverGlobal.ProxyURL())
}

//export GetFileInfoListByArchived
func GetFileInfoListByArchived(archived bool) *C.char {
	result, err := serverGlobal.AllDao().FileInfoDao.AllItemsByArchived(context.Background(), archived)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(result)
}

//export ArticleFromFileInfo
func ArticleFromFileInfo(fileInfoC *C.char) *C.char {
	var fileInfo model.FileInfo
	err := json.Unmarshal([]byte(C.GoString(fileInfoC)), &fileInfo)
	if err != nil {
		return CharErr(err.Error())
	}
	art, err := serverGlobal.ArticleFromGobGZPath(fileInfo.FilePath)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(art)
}

//export GetFileInfoBySourceURL
func GetFileInfoBySourceURL(sourceUrl *C.char) *C.char {
	item, err := serverGlobal.AllDao().FileInfoDao.ItemBySourceUrl(ctx, C.GoString(sourceUrl))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(item)

}

//export DeleteGobFile
func DeleteGobFile(id int64) *C.char {
	err := serverGlobal.DeleteGobFile(id)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export UpdateFileInfo
func UpdateFileInfo(fileInfoC *C.char) *C.char {
	var fileInfo model.FileInfo
	err := json.Unmarshal([]byte(C.GoString(fileInfoC)), &fileInfo)
	if err != nil {
		return CharErr(err.Error())
	}
	err = serverGlobal.AllDao().FileInfoDao.Update(ctx, &fileInfo)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export SetProxyUrl
func SetProxyUrl(netProxy *C.char) *C.char {
	err := serverGlobal.SetProxyUrl(C.GoString(netProxy))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()

}

//export SetXpathExpr
func SetXpathExpr(expr *C.char) *C.char {
	err := serverGlobal.SetXpathExpr(C.GoString(expr))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()

}

//export RestoreFromShareServer
func RestoreFromShareServer(ipC *C.char, port int, code int64, syncKnownWords bool, tempDir *C.char, syncToadyWordCount, syncByRemoteArchived bool) *C.char {
	err := serverGlobal.RestoreFromShareServer(C.GoString(ipC), port, code, syncKnownWords, C.GoString(tempDir), syncToadyWordCount, syncByRemoteArchived)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export AllKnownWordsMap
func AllKnownWordsMap() *C.char {
	items, err := serverGlobal.AllDao().KnownWordsDao.AllItems(ctx)
	if err != nil {
		return CharErr(err.Error())
	}
	var result = make(map[string]mtype.WordKnownLevel)
	for _, item := range items {
		result[item.Word] = item.Level
	}
	return CharOk(result)
}

//export SearchByKeyWordWithDefault
func SearchByKeyWordWithDefault(keyWordC *C.char) *C.char {
	items := dict.SearchByKeyWord(C.GoString(keyWordC), dict.DefaultDictWordMap)
	return CharOk(items)
}

//export FixMyKnownWords
func FixMyKnownWords() *C.char {
	err := serverGlobal.FixMyKnownWords()
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export GetIPv4s
func GetIPv4s() *C.char {
	addrs, _ := net.InterfaceAddrs()
	var ips []string // not include loopback address
	for _, addr := range addrs {
		ip, _, err := net.ParseCIDR(addr.String())
		if err != nil {
			continue
		}
		if ip.IsLoopback() {
			continue
		}
		// ipv4 only
		if ip.To4() == nil {
			continue
		}
		ips = append(ips, ip.String())
	}
	sort.Slice(ips, func(i, j int) bool {
		a := net.ParseIP(ips[i]).To4()
		b := net.ParseIP(ips[j]).To4()
		for k := 0; k < net.IPv4len; k++ {
			if a[k] < b[k] {
				return true
			}
		}
		return false
	})
	return CharOk(ips)
}

// DropAndReCreateDB drop and re-create db

//export ReadMessage
func ReadMessage() *C.char {
	msg := serverGlobal.ReadMessage()
	return C.CString(msg)
}

//export DropAndReCreateDB
func DropAndReCreateDB() *C.char {
	return CharErr("Can't use this function in production environment")
	err := serverGlobal.DropAndReCreateDB()
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export DBExecute
func DBExecute(sqlC *C.char) *C.char {
	return CharErr("Can't use this function in production environment")
	err := serverGlobal.GDB().Exec(C.GoString(sqlC)).Error
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export VacuumDB
func VacuumDB() *C.char {
	rowAffects, err := serverGlobal.VacuumDB(context.Background())
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(rowAffects)
}

//export DBSize
func DBSize() *C.char {
	size, err := serverGlobal.DBSize()
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(size)
}

// AllWordsByOrder order int 1: id desc, 2: id asc ,3 words desc, 4 words asc

//export AllWordsByCreateDayAndOrder
func AllWordsByCreateDayAndOrder(createDay, order int64) *C.char {
	var items []string
	var err error
	if order == 1 {
		items, err = serverGlobal.AllDao().KnownWordsDao.AllWordsByCreateDayWithIdDesc(ctx, createDay)
	} else {
		items, err = serverGlobal.AllDao().KnownWordsDao.AllWordsByCreateDayWithIdAsc(ctx, createDay)
	}
	if err != nil {
		return CharErr(err.Error())
	}
	switch order {
	case 3:
		sort.Slice(items, func(i, j int) bool {
			return items[i] > items[j]
		})
	case 4:
		sort.Slice(items, func(i, j int) bool {
			return items[i] < items[j]
		})
	}
	return CharList(items)
}
