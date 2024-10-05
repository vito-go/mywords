package main

import "C"
import (
	"mywords/client"
	"mywords/pkg/log"
	"net/http"
	"path/filepath"
	"sync/atomic"
	"time"
)

func init() {
	// flutter 中的日志是 UTC 时间，所以这里要设置时区
	time.Local = time.FixedZone("CST", 8*3600)
}

var initialized atomic.Bool

//export Init
func Init(rootDataDirC *C.char) {
	rootDataDir := C.GoString(rootDataDirC)
	// 非web版本
	// 非web版本 dictRunPort 传 -1, 表示不启动 web dict 服务
	initGlobal(rootDataDir, 0)
	// if 18960 start error with 18960, it will use a random port
	fs := http.Dir(filepath.ToSlash(filepath.Join(rootDataDir, webDir)))
	err := serverGlobal.StartWebOnline(18960, fs, serverHTTPCallFunc)
	if err != nil {
		log.Ctx(ctx).Error(err.Error())
	}
}

const webDir = "web"

func initGlobal(rootDataDir string, dictRunPort int) {
	if initialized.Swap(true) {
		return
	}
	var err error
	serverGlobal, err = client.NewClient(rootDataDir, dictRunPort)
	if err != nil {
		panic(err)
	}
}
