//go:build !flutter

package main

import (
	"embed"
	"flag"
	"fmt"
	"mywords/mylog"
	"net"
	"net/http"
	"path/filepath"
	"runtime"
	"time"
)

// 请把flutter build web的文件放到web目录下 否则编译不通过 pattern web/*: no matching files found
//
//go:embed web/*
var webEmbed embed.FS

func main() {

	defaultRootDir, err := getApplicationDir()
	if err != nil {
		panic(err)
	}
	port := flag.Int("port", 18960, "http server port")
	dictPort := flag.Int("dictPort", 18961, "dict port")
	embeded := flag.Bool("embed", true, "embedded web")
	rootDir := flag.String("rootDir", defaultRootDir, "root dir")
	flag.Parse()
	killOldPidAndGenNewPid(*rootDir)
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		panic(err)
	}
	initGlobal(*rootDir, *dictPort)
	mux := http.NewServeMux()
	mux.HandleFunc("/call/", serverHTTPCallFunc)
	mux.HandleFunc("/_addDictWithFile", addDictWithFile)
	mux.HandleFunc("/_downloadBackUpdate", downloadBackUpdate)
	mux.HandleFunc("/_webParseAndSaveArticleFromFile", webParseAndSaveArticleFromFile)
	mux.HandleFunc("/_webRestoreFromBackUpData", webRestoreFromBackUpData)

	if *embeded {
		// 请把flutter build web的文件放到web目录下
		mux.Handle("/", http.FileServer(http.FS(&webEmbedHandler{webEmbed: webEmbed})))
	} else {
		// 本地开发时，使用flutter web的文件, 请不要在生产环境使用，以防build/web目录被删除, 例如flutter clean
		_, file, _, ok := runtime.Caller(0)
		if ok {
			dir := filepath.ToSlash(filepath.Join(filepath.Dir(file), "../../../mywords-flutter/build/web"))
			mylog.Info("embedded false", "dir", dir)
			mux.Handle("/", http.FileServer(http.Dir(dir)))
		} else {
			panic("runtime.Caller failed")
		}
	}
	mylog.Info("server start", "port", *port, "rootDir", *rootDir)
	go func() {
		time.Sleep(time.Second)
		openBrowser(fmt.Sprintf("http://localhost:%d", *port))
	}()
	if err = http.Serve(lis, mux); err != nil {
		panic(err)
	}
}
