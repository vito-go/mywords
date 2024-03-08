package main

import "C"
import (
	"mywords/dict"
	"mywords/server"
	"sync"
	"time"
)

func init() {
	// flutter 中的日志是 UTC 时间，所以这里要设置时区
	time.Local = time.FixedZone("CST", 8*3600)
}

var once sync.Once

//export Init
func Init(rootDataDir *C.char, proxyUrl *C.char) {
	once.Do(func() {
		initGlobal(C.GoString(rootDataDir), C.GoString(proxyUrl))
	})
}
func initGlobal(rootDataDir string, proxyUrl string) {
	srv, err := server.NewServer(rootDataDir, proxyUrl)
	if err != nil {
		panic(err)
	}
	serverGlobal = srv
	multiDictGlobal = dict.NewMultiDictZip(rootDataDir)
	go multiDictGlobal.Init()
}
