package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestMain(m *testing.M) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	initGlobal(filepath.Join(homeDir, ".local/share/com.example.mywords"), "")
	GetChartDataAccumulate()
	select {}
}
