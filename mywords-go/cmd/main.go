//go:build !flutter

package main

import (
	"embed"
	"flag"
	"io/fs"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
)

//go:embed web/*
var webEmbed embed.FS

func main() {
	defaultRootDir, err := getApplicationDir()
	if err != nil {
		panic(err)
	}
	webPort := flag.Int64("port", 18960, "http client port")
	initGlobal(defaultRootDir, 18961)
	err = serverGlobal.StartWebOnline(*webPort, http.FS(&webEmbedHandler{webEmbed: webEmbed}), serverHTTPCallFunc)
	if err != nil {
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
