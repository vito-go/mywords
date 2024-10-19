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

//go:generate make build-web
func main() {
	defaultRootDir, err := getApplicationDir()
	if err != nil {
		panic(err)
	}
	webPort := flag.Int64("runningPort", 18960, "web online port")
	dictRunPort := flag.Int("dictPort", 18961, "word query port")
	flag.Parse()
	initGlobal(defaultRootDir, *dictRunPort)
	serverGlobal.SetIsWebTrue()
	err = serverGlobal.StartWebOnline(*webPort, http.FS(webEmbed), serverHTTPCallFunc)
	if err != nil {
		panic(err)
	}
}

func getApplicationDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	defaultRootDir := filepath.Join(homeDir, ".local/share/com.mywords.android")
	switch runtime.GOOS {
	case "windows":
		defaultRootDir = filepath.Join(homeDir, "AppData/Roaming/com.example/mywords")
	case "darwin":
		defaultRootDir = filepath.Join(homeDir, "Library/Application Support/com.mywords.android")
	case "linux":
		defaultRootDir = filepath.Join(homeDir, ".local/share/com.mywords.android")
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
