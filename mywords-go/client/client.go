package client

import (
	"context"
	"golang.org/x/time/rate"
	"gorm.io/gorm"
	"mywords/artical"
	"mywords/client/dao"
	"mywords/pkg/db"
	"mywords/pkg/log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"sync"
	"sync/atomic"
)

const (
	dbDir  = "db"
	dbName = "mywords.db"
)

type Client struct {
	rootDataDir string
	xpathExpr   string //must can compile
	//knownWordsMap map[string]map[string]WordKnownLevel // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//fileInfoMap1        map[string]FileInfo                  // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}

	mux         sync.Mutex //
	shareServer *http.Server
	shareOpened atomic.Bool
	// multicast

	//chartDateLevelCountMap map[string]map[WordKnownLevel]map[string]struct{} // date: {1: {"words":{}}, 2: 200, 3: 300}

	// 新字段

	rootDir string

	gdb             *gorm.DB
	dbPath          string
	allDao          *dao.AllDao
	codeContentChan chan CodeContent
	pprofListen     net.Listener //may be nil

	messageLimiter *rate.Limiter
	closed         atomic.Bool
	//		//
	//	//knownWordsMap map[string]map[string]WordKnownLevel // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//	knownWordsMap *MySyncMapMap[string, WordKnownLevel] // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//	//fileInfoMap1        map[string]FileInfo                  // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//	fileInfoMap         *MySyncMap[FileInfo] // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//	fileInfoArchivedMap *MySyncMap[FileInfo] // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//
	//	mux           sync.Mutex //
	//	shareListener net.Listener
	//	// multicast
	//	remoteHostMap sync.Map // remoteHost: port
	//
	//	//chartDateLevelCountMap map[string]map[WordKnownLevel]map[string]struct{} // date: {1: {"words":{}}, 2: 200, 3: 300}
	//	chartDateLevelCountMap *MySyncMapMap[WordKnownLevel, map[string]struct{}] // date: {1: {"words":{}}, 2: 200, 3: 300}

}

func NewClient(rootDataDir string) (*Client, error) {
	// 获取平台 GOOS

	rootDataDir = filepath.ToSlash(rootDataDir)
	if err := os.MkdirAll(rootDataDir, 0755); err != nil {
		return nil, err
	}

	dbDir := filepath.ToSlash(filepath.Join(rootDataDir, dbDir))
	err := os.MkdirAll(dbDir, os.ModePerm)
	if err != nil {
		return nil, err
	}
	dbPath := filepath.ToSlash(filepath.Join(dbDir, dbName))
	gdb, err := db.NewDB(dbPath)
	if err != nil {
		return nil, err
	}
	allDao := dao.NewAllDao(gdb)
	if err := os.MkdirAll(filepath.Join(rootDataDir, dataDir, gobFileDir), 0755); err != nil {
		return nil, err
	}
	client := &Client{
		rootDataDir:     rootDataDir,
		xpathExpr:       artical.DefaultXpathExpr,
		allDao:          allDao,
		rootDir:         rootDataDir,
		gdb:             gdb,
		dbPath:          dbPath,
		codeContentChan: make(chan CodeContent, 1024),
		shareOpened:     atomic.Bool{},
	}
	err = client.InitCreateTables()
	if err != nil {
		return nil, err
	}

	pprofLis, err := client.startPProf()
	if err != nil {
		return nil, err
	}
	client.pprofListen = pprofLis
	log.SetHook(func(ctx context.Context, record *log.HookRecord) {
		msg := record.Content
		if !debug.Load() {
			if runtime.GOOS == "android" || runtime.GOOS == "ios" {
				client.SendCodeContent(CodeLog, msg)
			}
		}
		level := record.Level

		if level == log.LevelError {

		} else if level == log.LevelWarn {

		}

	})

	// restore
	client.restoreFileInfoFromArchived()
	client.restoreFileInfoFromNotArchived()
	client.restoreFromDailyChartDataFile()
	return client, nil
}
