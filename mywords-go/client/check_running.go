package client

import (
	"mywords/pkg/log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
)

func checkRunning(rootDir string) bool {
	// kill old pid
	pidFile := filepath.Join(rootDir, "mywords.pid")
	defer func() {
		// write new pid
		pid := os.Getpid()
		err := os.WriteFile(pidFile, []byte(strconv.Itoa(pid)), os.ModePerm)
		if err != nil {
			log.Println("write pid file error", "err", err)
			return
		}
		log.Println("write pid file", "pid", pid)
	}()
	data, err := os.ReadFile(pidFile)
	if err != nil {
		return false
	}
	pidStr := strings.TrimSpace(string(data))
	pid, err := strconv.Atoi(pidStr)
	if err != nil {
		return false
	}
	process, err := os.FindProcess(pid)
	if err != nil {
		return false
	}
	err = process.Signal(syscall.Signal(0))
	if err != nil {
		return false
	}
	return true
}
