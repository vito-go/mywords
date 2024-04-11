//go:build !flutter

package main

import (
	"embed"
	"flag"
	"fmt"
	"io/fs"
	"mywords/mylog"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"time"
)

//go:embed web/*
var webEmbed embed.FS

func main() {

	defaultRootDir, err := getApplicationDir()
	if err != nil {
		panic(err)
	}
	port := flag.Int("port", 18960, "http server port")
	dictPort := flag.Int("dictPort", 18961, "dict port")
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
	mux.Handle("/", http.FileServer(http.FS(&webEmbedHandler{webEmbed: webEmbed})))
	mylog.Info("server start", "port", *port, "rootDir", *rootDir)
	go func() {
		time.Sleep(time.Second)
		openBrowser(fmt.Sprintf("http://localhost:%d", *port))
	}()
	if err = http.Serve(lis, mux); err != nil {
		panic(err)
	}
}

func getApplicationDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	defaultRootDir := filepath.Join(homeDir, ".local/share/com.example.mywords")
	switch runtime.GOOS {
	case "windows":
		defaultRootDir = filepath.Join(homeDir, "AppData/Roaming/com.example/mywords")
	case "darwin":
		defaultRootDir = filepath.Join(homeDir, "Library/Application Support/com.example.mywords")
	case "linux":
		defaultRootDir = filepath.Join(homeDir, ".local/share/com.example.mywords")
	}
	// 请注意，如果同时打开多个应用，可能会导致目录冲突，数据造成不一致或丢失
	defaultRootDir = filepath.ToSlash(defaultRootDir)
	return defaultRootDir, err
}

type webEmbedHandler struct {
	webEmbed embed.FS
}

func (f webEmbedHandler) Open(name string) (fs.File, error) {
	// 在windows系统下必须用toSlash 封装一下路径，否则，web\index.html!=web/index.html
	name = filepath.ToSlash(filepath.Join("web", name))
	return f.webEmbed.Open(name)
}
