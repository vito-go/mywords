package main

import "C"
import (
	"bytes"
	"encoding/json"
	"fmt"
	"runtime"
)

var (
	buildTime string = ""
	gitCommit string = ""
)

//export GoBuildInfoString
func GoBuildInfoString() *C.char {
	s := goBuildInfoString()
	return C.CString(s)
}

//export GoBuildInfoMap
func GoBuildInfoMap() *C.char {
	m := buildInfoMap()
	b, _ := json.Marshal(m)
	return C.CString(string(b))
}
func buildInfoMap() map[string]string {
	m := map[string]string{
		"buildTime":       buildTime,
		"gitCommit":       gitCommit,
		"runtime.Version": runtime.Version(),
		"runtime.GOOS":    runtime.GOOS,
		"runtime.GOARCH":  runtime.GOARCH,
	}
	return m
}

func goBuildInfoString() string {
	var buf bytes.Buffer
	buf.WriteString(fmt.Sprintf("Go buildTime: %s\n", buildTime))
	buf.WriteString(fmt.Sprintf("Go gitCommit: %s\n", gitCommit))
	buf.WriteString(fmt.Sprintf("Go runtime.Version: %s\n", runtime.Version()))
	buf.WriteString(fmt.Sprintf("Go runtime.GOOS: %s\n", runtime.GOOS))
	buf.WriteString(fmt.Sprintf("Go runtime.GOARCH: %s\n", runtime.GOARCH))
	return buf.String()
}
