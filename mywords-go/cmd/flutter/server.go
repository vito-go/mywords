package main

import "C"
import (
	"encoding/json"
	"mywords/artical"
	"mywords/dict"
	"mywords/mylog"
	"mywords/server"
	"mywords/util"
	"strings"
)

var serverGlobal *server.Server

//export UpdateKnownWords
func UpdateKnownWords(level int, c *C.char) *C.char {
	var words []string
	err := json.Unmarshal([]byte(C.GoString(c)), &words)
	if err != nil {
		return CharErr(err.Error())
	}
	mylog.Info("UpdateKnownWords", "level", level, "words", words)
	err = serverGlobal.UpdateKnownWords(server.WordKnownLevel(level), words...)
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

//export RestoreFromBackUpData
func RestoreFromBackUpData(zipFile *C.char) *C.char {
	err := serverGlobal.RestoreFromBackUpData(C.GoString(zipFile))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export ParseAndSaveArticleFromSourceUrlAndContent
func ParseAndSaveArticleFromSourceUrlAndContent(sourceUrl *C.char, htmlContentC *C.char) *C.char {
	art, err := serverGlobal.ParseAndSaveArticleFromSourceUrlAndContent(C.GoString(sourceUrl), []byte(C.GoString(htmlContentC)))
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

//export KnownWordsCountMap
func KnownWordsCountMap() *C.char {
	var m = make(map[server.WordKnownLevel]int, 3)
	for _, knownWordsMap := range serverGlobal.KnownWordsMap() {
		for _, level := range knownWordsMap {
			if level <= 0 {
				continue
			}
			m[level]++
		}
	}
	return CharOk(m)
}

//export ParseVersion
func ParseVersion() *C.char {
	return CharOk(artical.ParseVersion)
}

//export ShowFileInfoList
func ShowFileInfoList() *C.char {
	return CharOk(serverGlobal.ShowFileInfoList())
}

//export GetArchivedFileInfoList
func GetArchivedFileInfoList() *C.char {
	return CharOk(serverGlobal.GetArchivedFileInfoList())
}

//export ArticleFromGobFile
func ArticleFromGobFile(fileName *C.char) *C.char {
	art, err := serverGlobal.ArticleFromGobFile(C.GoString(fileName))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(art)
}

//export DeleteGobFile
func DeleteGobFile(fileName *C.char) *C.char {
	err := serverGlobal.DeleteGobFile(C.GoString(fileName))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export ArchiveGobFile
func ArchiveGobFile(fileName *C.char) *C.char {
	err := serverGlobal.ArchiveGobFile(C.GoString(fileName))
	if err != nil {
		return CharErr(err.Error())
	}
	return CharSuccess()
}

//export UnArchiveGobFile
func UnArchiveGobFile(fileName *C.char) *C.char {
	err := serverGlobal.UnArchiveGobFile(C.GoString(fileName))
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
func RestoreFromShareServer(ipC *C.char, port int, code int64, tempDir *C.char, syncToadyWordCount bool) *C.char {
	err := serverGlobal.RestoreFromShareServer(C.GoString(ipC), port, code, C.GoString(tempDir), syncToadyWordCount)
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

//export LevelDistribute
func LevelDistribute(artC *C.char) *C.char {
	var wordInfos []string
	err := json.Unmarshal([]byte(C.GoString(artC)), &wordInfos)
	if err != nil {
		return CharErr(err.Error())
	}
	l := serverGlobal.LevelDistribute(wordInfos)
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
