package main

import "C"
import (
	"mywords/dict"
	"mywords/server"
	"sync"
	"time"
)

func main() {
	// must Init when using the exported method in this package
}

func init() {
	// flutter 中的日志是 UTC 时间，所以这里要设置时区
	time.Local = time.FixedZone("CST", 8*3600)
}

var once sync.Once

//export Init
func Init(rootDataDir *C.char, proxyUrl *C.char) {
	once.Do(func() {
		srv, err := server.NewServer(C.GoString(rootDataDir), C.GoString(proxyUrl))
		if err != nil {
			panic(err)
		}
		serverGlobal = srv
		multiDictGlobal = dict.NewMultiDictZip(C.GoString(rootDataDir))
		go multiDictGlobal.Init()
	})
}
