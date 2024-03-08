//go:build !flutter

package main

import (
	"os"
	"path/filepath"
)

// 可以命令行的方式运行
func main() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	initGlobal(filepath.Join(homeDir, ".local/share/com.example.mywords"), "")
	err = serverGlobal.ShareOpen(18964, 890604)
	if err != nil {
		panic(err)
	}
	select {}
}
