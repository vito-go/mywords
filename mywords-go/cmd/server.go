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
	info, err := serverGlobal.AllDao().KeyValueDao.QueryShareInfo(ctx)
	if err != nil {
		return CharErr(err.Error())
	}
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

//export ParseAndSaveArticleFromSourceUrl
func ParseAndSaveArticleFromSourceUrl(sourceUrl *C.char) *C.char {
	art, err := serverGlobal.ParseAndSaveArticleFromSourceUrl(C.GoString(sourceUrl))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(art)
}

//export ParseAndSaveArticleFromFile
func ParseAndSaveArticleFromFile(pathC *C.char) *C.char {
	art, err := serverGlobal.ParseAndSaveArticleFromFile(C.GoString(pathC))
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

//export ParseAndSaveArticleFromSourceUrlAndContent
func ParseAndSaveArticleFromSourceUrlAndContent(sourceUrl *C.char, htmlContentC *C.char, lastModified int64) *C.char {
	art, err := serverGlobal.ParseAndSaveArticleFromSourceUrlAndContent(C.GoString(sourceUrl), []byte(C.GoString(htmlContentC)), lastModified)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(art)
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

//export ShowFileInfoList
func ShowFileInfoList() *C.char {
	result, err := serverGlobal.AllDao().FileInfoDao.AllItemsByArchived(context.Background(), false)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(result)
}

//export GetArchivedFileInfoList
func GetArchivedFileInfoList() *C.char {
	result, err := serverGlobal.AllDao().FileInfoDao.AllItemsByArchived(context.Background(), true)
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
	art, err := serverGlobal.ArticleFromFileInfo(&fileInfo)
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

//export QueryWordLevel
func QueryWordLevel(wordC *C.char) *C.char {
	l, _ := serverGlobal.QueryWordLevel(C.GoString(wordC))
	return CharOk(l)
}

//export QueryWordsLevel
func QueryWordsLevel(wordC *C.char) *C.char {
	var words []string
	err := json.Unmarshal([]byte(C.GoString(wordC)), &words)
	if err != nil {
		return CharErr(err.Error())
	}
	result, err := serverGlobal.QueryWordsLevel(words...)
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(result)
}

//export LevelDistribute
func LevelDistribute(artC *C.char) *C.char {
	var words []string
	err := json.Unmarshal([]byte(C.GoString(artC)), &words)
	if err != nil {
		return CharErr(err.Error())
	}
	l := serverGlobal.LevelDistribute(words)
	return CharOk(l)
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
