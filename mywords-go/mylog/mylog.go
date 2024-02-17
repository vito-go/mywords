package mylog

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

type logger struct {
	mux        sync.Mutex // to init only once
	writer     io.Writer  // io.Writer
	debug      atomic.Bool
	callerSkip atomic.Int64 // runtime.Caller skip, to show file and line
}

// SetCallerSkip .
func SetCallerSkip(skip int64) {
	logStd.callerSkip.Store(skip)
}

// SetDebug .
func SetDebug(debug bool) {
	logStd.debug.Store(debug)
}

// SetWriter .
func SetWriter(w io.Writer) {
	logStd.mux.Lock()
	defer logStd.mux.Unlock()
	logStd.writer = w
}

var logStd = logger{
	mux:        sync.Mutex{},
	writer:     os.Stdout,
	callerSkip: atomic.Int64{},
	debug:      atomic.Bool{},
}

type level int

const (
	LevelDebug level = -4
	LevelInfo  level = 0
	LevelWarn  level = 4
	LevelError level = 8
)

func (l level) String() string {
	switch l {
	case LevelInfo:
		return "INFO"
	case LevelWarn:
		return "WARN"
	case LevelError:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// Info logs a message at level Info on the standard logger.
func Info(msg string, args ...interface{}) {
	WriteOut(LevelInfo, msg, args...)
}

// Warn logs a message at level Warn on the standard logger.
func Warn(msg string, args ...interface{}) {
	WriteOut(LevelWarn, msg, args...)

}

func Infof(format string, a ...interface{}) {
	WriteOut(LevelInfo, fmt.Sprintf(format, a...))
}
func Warnf(format string, a ...interface{}) {
	WriteOut(LevelWarn, fmt.Sprintf(format, a...))
}
func Errorf(format string, a ...interface{}) {
	WriteOut(LevelError, fmt.Sprintf(format, a...))
}

// Error logs a message at level Error on the standard logger.
func Error(msg string, args ...interface{}) {
	WriteOut(LevelError, msg, args...)
}

// quoteUnicode is the set of Unicode characters that are quoted.  "　“”" is Chinese space and quotation marks
var quoteUnicode = string([]byte{'\a', '\b', '\f', '\n', '\r', '\t', '\v', '\\', '\'', '"', ' ', '='}) + "　“”"

// WriteOut export for (*logger)writeOut. in order to runtime.Caller(2) to get caller to support multi-platform
func WriteOut(l level, msg string, args ...any) (int, error) {
	return logStd.writeOut(l, msg, args...)
}
func (lg *logger) writeOut(l level, msg string, args ...any) (int, error) {
	outBuf := outBufPool.Get().(*bytes.Buffer)
	outBuf.Reset() // 日志会被覆盖？ 在编译为so文件时，会出现日志被覆盖/错乱的情况，原因未知,原因知道了　outBuf在函数return后不应该在使用
	defer func() { outBufPool.Put(outBuf) }()
	outBuf.WriteString("[")
	outBuf.WriteString(l.String())
	outBuf.WriteString("] ")
	outBuf.WriteString(time.Now().Format("2006-01-02 15:04:05.000 "))
	if lg.debug.Load() {
		_, file, line, ok := runtime.Caller(int(lg.callerSkip.Load()))
		if ok {
			outBuf.WriteString(fmt.Sprintf("%s:%d ", filepath.Base(file), line))
		}
	}
	outBuf.WriteString(msg)
	if len(args) == 0 {
		outBuf.WriteString("\n")
		lg.mux.Lock()
		defer lg.mux.Unlock()
		return lg.writer.Write(outBuf.Bytes())
	}
	for i := 0; i < len(args); i += 2 {
		// key=value
		if i+1 < len(args) {
			// key=value
			if v, ok := args[i+1].(string); ok {
				if strings.ContainsAny(v, quoteUnicode) {
					outBuf.WriteString(fmt.Sprintf(" %s=%q", args[i], v))
					continue
				}
			}
			outBuf.WriteString(fmt.Sprintf(" %s=%+v", args[i], args[i+1]))
			continue
		}
		//!BADKEY
		outBuf.WriteString(fmt.Sprintf(" !BADKEY=%+v", args[i]))
	}
	outBuf.WriteByte('\n')
	lg.mux.Lock()
	defer lg.mux.Unlock()
	return lg.writer.Write(outBuf.Bytes())
}

var outBufPool = sync.Pool{New: func() interface{} { return bytes.NewBuffer(make([]byte, 0, 512)) }} // default 1 kb

func init() {
	logStd.debug.Store(false)
	logStd.callerSkip.Store(3)
}
