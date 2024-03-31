package main

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

// TestMain Debug here
func TestMain(m *testing.M) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	initGlobal(filepath.Join(homeDir, ".local/share/com.example.mywords"), "", 0)
	GetChartDataAccumulate()
	//initGlobal needs time to start
	time.Sleep(time.Second * 3)
	content, err := multiDictGlobal.GetHTMLRenderContentByWord("apple")
	if err != nil {
		panic(err)
	}
	os.WriteFile("apple.html", []byte(content), 0644)
	//select {}
}
