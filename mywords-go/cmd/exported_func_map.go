package main

// 反射调用函数，效率分析
// 1. 当没有参数时候，且函数比较简单的时候，直接调用函数比反射调用函数快，反射调用函数需要768ns，直接调用函数需要553ns，快30%左右
// 2. 当有参数时候，且函数比较简单的时候，直接调用函数比反射调用函数快， 快60%
// 3. 当函数逻辑比较复杂时候，反射调用函数和直接调用函数差距不大，直接调用快6%左右

//在Go语言中，无法直接将结构体的方法编译为.so库中的导出函数。如果想要导出函数，你应该将这些函数定义为包级别的函数，而不是结构体的方法。导出函数需要是包级别的，而不是特定于某个结构体的方法。
//  所有将所有的导出方法放入一个map中，然后在导出函数中通过传入的方法名来调用对应的方法，以实现http server的功能。
//  通过这种方式，我们可以在flutter中调用Go语言的导出函数，从而实现http server的功能。

// exportedFuncMap 保存了所有的导出函数, key为导出函数的名字，value为导出函数的实现
var exportedFuncMap = map[string]any{
	"AddDict":                        AddDict,
	"AllKnownWordMap":                AllKnownWordMap,
	"UpdateFileInfo":                 UpdateFileInfo,
	"GetFileInfoBySourceURL":         GetFileInfoBySourceURL,
	"BackUpData":                     BackUpData,
	"CharErr":                        CharErr,
	"CharSuccess":                    CharSuccess,
	"DelDict":                        DelDict,
	"DeleteGobFile":                  DeleteGobFile,
	"DictList":                       DictList,
	"DictWordQuery":                  DictWordQuery,
	"DictWordQueryLink":              DictWordQueryLink,
	"FinalHtmlBasePathWithOutHtml":   FinalHtmlBasePathWithOutHtml,
	"FixMyKnownWords":                FixMyKnownWords,
	"GetArchivedFileInfoList":        GetArchivedFileInfoList,
	"GetChartData":                   GetChartData,
	"GetChartDataAccumulate":         GetChartDataAccumulate,
	"GetDefaultDict":                 GetDefaultDict,
	"GetHTMLRenderContentByWord":     GetHTMLRenderContentByWord,
	"GetToadyChartDateLevelCountMap": GetToadyChartDateLevelCountMap,
	"GetUrlByWord":                   GetUrlByWord,
	"Init":                           Init,
	"KnownWordsCountMap":             KnownWordsCountMap,
	"LevelDistribute":                LevelDistribute,
	"ReparseArticleFileInfo":         ReparseArticleFileInfo,
	"RenewArticleFileInfo":           RenewArticleFileInfo,
	"NewArticleFileInfoBySourceURL":  NewArticleFileInfoBySourceURL,
	"ParseVersion":                   ParseVersion,
	"ProxyURL":                       ProxyURL,
	"PrintError":                     PrintError,
	"PrintInfo":                      PrintInfo,
	"PrintWarn":                      PrintWarn,
	"Println":                        Println,
	"QueryWordLevel":                 QueryWordLevel,
	"QueryWordsLevel":                QueryWordsLevel,
	"RestoreFromBackUpData":          RestoreFromBackUpData,
	"RestoreFromShareServer":         RestoreFromShareServer,
	"SearchByKeyWord":                SearchByKeyWord,
	"SearchByKeyWordWithDefault":     SearchByKeyWordWithDefault,
	"SetDefaultDict":                 SetDefaultDict,
	"SetLogCallerSkip":               SetLogCallerSkip,
	"SetLogDebug":                    SetLogDebug,
	"SetLogUrl":                      SetLogUrl,
	"SetProxyUrl":                    SetProxyUrl,
	"SetXpathExpr":                   SetXpathExpr,
	"ShareClosed":                    ShareClosed,
	"ShareOpen":                      ShareOpen,
	"GetShareInfo":                   GetShareInfo,
	"ShowFileInfoList":               ShowFileInfoList,
	"TodayKnownWordMap":              TodayKnownWordMap,
	"UpdateDictName":                 UpdateDictName,
	"UpdateKnownWordLevel":           UpdateKnownWordLevel,
	"GetIPv4s":                       GetIPv4s,
}
