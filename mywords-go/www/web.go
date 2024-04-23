//go:build !embed

package www

import (
	"net/http"
	"os"
	"path/filepath"
	"runtime"
)

var FileSystem http.FileSystem = http.Dir("web")

func init() {
	// 本地开发时，使用flutter web的文件, 请不要在生产环境使用，以防build/web目录被删除, 例如flutter clean
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		panic("runtime.Caller(0): can not find the program counter for the location in this frame")
	}
	var webDir = filepath.ToSlash(filepath.Join(filepath.Dir(file), "web"))
	fileInfo, err := os.Stat(webDir)
	if err != nil || !fileInfo.IsDir() {
		webDir = filepath.ToSlash(filepath.Join(filepath.Dir(file), "../../../mywords-flutter/build/web"))
	}
	println("web dir: " + webDir)
	FileSystem = http.Dir(webDir)
}
