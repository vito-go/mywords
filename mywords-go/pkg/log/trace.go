package log

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"net"
	"strconv"
	"strings"
	"time"
)

func Tid() string {
	return fmt.Sprintf("%d%03d", time.Now().UnixMicro(), ipCode)
}

var ipCode int64

func init() {
	priIP, err := getPrivateIP()
	if err != nil {
		fmt.Println("get private ip error", err)
		return
	}
	var ipCodeStr string
	if ss := strings.Split(priIP, "."); len(ss) == 4 {
		ipCodeStr = ss[3]
	}
	ipCode, err = strconv.ParseInt(ipCodeStr, 10, 64)
	if err != nil {
		fmt.Println("parse ip code error", err)
	}
}

type contextKey struct {
	name string
}

var TraceIdKey = &contextKey{"traceId"}

func NewContext() context.Context {
	return context.WithValue(context.Background(), TraceIdKey, RandomIdWithIPSuffix())
}
func RandomId() string {
	return RandStringByLen(7)
}
func RandomIdWithIPSuffix() string {
	return RandStringByLen(7) + "-" + strconv.FormatInt(ipCode, 10)
}

const letterBytes = "0123456789abcdefghijklmnopqrstuvwxyz"
const letterBytesLen = int64(len(letterBytes))

func RandStringByLen(n int) string {
	b := make([]byte, n)
	for i := 0; i < n; i++ {
		idx := rand.Int63() % letterBytesLen
		b[i] = letterBytes[idx]
	}
	return string(b)
}

func getPrivateIP() (string, error) {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "", err
	}
	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok && ipNet.IP.IsPrivate() {
			return ipNet.IP.String(), err
		}
	}
	return "", errors.New("no private ip")
}
