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
func Init(rootDataDirC *C.char) {
	once.Do(func() {
		rootDataDir := C.GoString(rootDataDirC)
		// 非web版本
		killOldPidAndGenNewPid(rootDataDir)
		initGlobal(rootDataDir, 0)
	})
}
func initGlobal(rootDataDir string, dictRunPort int) {
	var err error
	serverGlobal, err = server.NewServer(rootDataDir)
	if err != nil {
		panic(err)
	}
	multiDictGlobal, err = dict.NewMultiDictZip(rootDataDir, dictRunPort)
	if err != nil {
		panic(err)
	}
}
