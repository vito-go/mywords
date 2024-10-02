package main

import (
	"mywords/pkg/log"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

// killOldPidAndGenNewPid kill old pid and generate new pid.
// It is used to ensure that only one instance of the program is running.
func killOldPidAndGenNewPid(rootDir string) {
	return
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
		return
	}
	pidStr := strings.TrimSpace(string(data))
	pid, err := strconv.Atoi(pidStr)
	if err != nil {
		return
	}
	process, err := os.FindProcess(pid)
	if err != nil {
		return
	}
	err = process.Kill()
	if err != nil {
		return
	}
	switch runtime.GOOS {
	case "darwin", "linux", "windows", "freebsd", "openbsd", "netbsd", "dragonfly":
		time.Sleep(time.Millisecond * 250)
		// wait for old process to exit
	}
	// kill log
	log.Println("kill old pid", "pid", pid)
	return
}
