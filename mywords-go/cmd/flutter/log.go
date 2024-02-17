package main

import "C"
import (
	"mywords/mylog"
	"mywords/mylog/flutterlog"
	"sync/atomic"
	"time"
)

//export Println
func Println(msg *C.char) {
	//mylog.Error("Flutter: " + C.GoString(msg))
	mylog.WriteOut(mylog.LevelInfo, C.GoString(msg))

}

//export PrintInfo
func PrintInfo(msg *C.char) {
	//mylog.Info("Flutter: " + C.GoString(msg))
	mylog.WriteOut(mylog.LevelInfo, C.GoString(msg))
}

//export PrintError
func PrintError(msg *C.char) {
	//mylog.Error("Flutter: " + C.GoString(msg))
	mylog.WriteOut(mylog.LevelError, C.GoString(msg))
}

//export PrintWarn
func PrintWarn(msg *C.char) {
	//mylog.Warn("Flutter: " + C.GoString(msg))
	mylog.WriteOut(mylog.LevelWarn, C.GoString(msg))
}

var flutterLoggerValue = atomic.Value{}

//export SetLogCallerSkip
func SetLogCallerSkip(skip int64) {
	mylog.SetCallerSkip(skip)
}

//export SetLogDebug
func SetLogDebug(debug bool) {
	mylog.SetDebug(debug)
}

//export SetLogUrl
func SetLogUrl(url *C.char, logNonce *C.char, debug bool) {
	v := flutterLoggerValue.Load()
	if v != nil {
		if oldLogger, ok := v.(*flutterlog.Logger); ok {
			oldLogger.Close()
		}
	}
	f := flutterlog.NewLogger(C.GoString(url), C.GoString(logNonce))
	mylog.SetDebug(debug)
	mylog.SetWriter(f)
	flutterLoggerValue.Store(f)
	if debug {
		mylog.Info("Flutter: SetLogUrl", `url`, C.GoString(url), `logNonce`, C.GoString(logNonce), `debug`, debug)
	} else {
		mylog.Info("Flutter: SetLogUrl", `url`, C.GoString(url), `debug`, debug)
	}
	mylog.Info("time.Local: " + time.Local.String())
}
