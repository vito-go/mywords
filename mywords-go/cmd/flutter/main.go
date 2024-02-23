package main

import "C"
import (
	"fmt"
	"mywords/dict"
	"mywords/server"
	"sync"
	"time"
)

func main() {
	// must Init when using the exported method in this package
	fmt.Println("Hello World from Flutter")
}

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
