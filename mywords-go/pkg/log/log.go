package log

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"gopkg.in/natefinch/lumberjack.v2"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

var initOnce atomic.Bool

func InitLogger(verbose bool, infoLogger *lumberjack.Logger, errLogger *lumberjack.Logger, options ...*Option) {
	if initOnce.Swap(true) {
		Ctx(context.Background()).Warn("logger has been initialized")
		return
	}
	var defaultInfoLogger *logger
	if verbose {
		defaultInfoLogger = &logger{Writer: io.MultiWriter(infoLogger, os.Stdout), prefix: ""}
	} else {
		defaultInfoLogger = &logger{Writer: infoLogger, prefix: ""}
	}
	defaultLogger.defaultInfoLogger = defaultInfoLogger
	defaultLogger.defaultWarnLogger = &logger{Writer: io.MultiWriter(errLogger, defaultInfoLogger), prefix: ""}
	defaultLogger.defaultErrorLogger = &logger{Writer: io.MultiWriter(errLogger, defaultInfoLogger), prefix: ""}
	for _, option := range options {
		prefix := fmt.Sprintf("[%s] ", option.LogName)
		defaultLogger.logMap[option.LogName] = &loggerWithLevel{
			infoLogger:  &logger{Writer: io.MultiWriter(option.Logger, defaultInfoLogger), prefix: prefix},
			warnLogger:  &logger{Writer: io.MultiWriter(option.Logger, errLogger, defaultInfoLogger), prefix: prefix},
			errorLogger: &logger{Writer: io.MultiWriter(option.Logger, errLogger, defaultInfoLogger), prefix: prefix},
		}
	}
}

type fieldLogger struct {
	ctx     context.Context
	logName Name
	kvs     []kv
}

func (w *fieldLogger) kvToJson() string {
	if len(w.kvs) == 0 {
		return ""
	}
	outBuf := outBufPool.Get().(*bytes.Buffer)
	outBuf.Reset()
	defer func() { outBufPool.Put(outBuf) }()
	outBuf.WriteString(" {")
	for i, kv := range w.kvs {
		if i > 0 {
			outBuf.WriteByte(',')
		}
		outBuf.WriteString(`"` + kv.key + `":` + kv.value)
	}
	outBuf.WriteByte('}')
	return outBuf.String()
}

type kv struct {
	key   string
	value string
}

func Ctx(ctx context.Context) *fieldLogger {
	return &fieldLogger{ctx: ctx}
}
func (w *fieldLogger) WithLogName(logName Name) *fieldLogger {
	w.logName = logName
	return w
}

// getLoggerByLevel 通过日志级别获取日志对象
func (w *fieldLogger) getLoggerByLevel(level Level) *logger {
	if w.logName != "" {
		if nameLogger, ok := defaultLogger.logMap[w.logName]; ok {
			switch level {
			case LevelInfo:
				return nameLogger.infoLogger
			case LevelWarn:
				return nameLogger.warnLogger
			case LevelError:
				return nameLogger.errorLogger
			}
		}
	}
	switch level {
	case LevelInfo:
		return defaultLogger.defaultInfoLogger
	case LevelWarn:
		return defaultLogger.defaultWarnLogger
	case LevelError:
		return defaultLogger.defaultErrorLogger
	default:
		return defaultLogger.defaultInfoLogger
	}
}

func (w *fieldLogger) WithField(key string, value interface{}) *fieldLogger {
	w.kvs = append(w.kvs, kv{key: key, value: stringify(value)})
	return w
}

func (w *fieldLogger) WithFields(k1 string, v1 interface{}, k2 string, v2 interface{}, kvs ...interface{}) *fieldLogger {
	w.kvs = append(w.kvs, kv{key: k1, value: stringify(v1)}, kv{key: k2, value: stringify(v2)})
	if len(kvs)%2 != 0 {
		// !BADKEY
		w.kvs = append(w.kvs, kv{key: "!BADKEY", value: fmt.Sprintf("%+v", kvs)})
		return w
	}
	for i := 0; i < len(kvs); i += 2 {
		key, ok := kvs[i].(string)
		if !ok {
			key = "!BADKEY"
		}
		w.kvs = append(w.kvs, kv{key: key, value: stringify(kvs[i+1])})
	}
	return w
}

func (w *fieldLogger) Info(args ...interface{}) {
	l := w.getLoggerByLevel(LevelInfo)

	outPut(w.ctx, l.prefix, l.Writer, LevelInfo, strings.TrimSpace(fmt.Sprintln(args...))+w.kvToJson())
}

func (w *fieldLogger) Infof(format string, args ...interface{}) {
	l := w.getLoggerByLevel(LevelInfo)
	outPut(w.ctx, l.prefix, l.Writer, LevelInfo, fmt.Sprintf(format, args...)+w.kvToJson())
}

func (w *fieldLogger) Warn(args ...interface{}) {
	l := w.getLoggerByLevel(LevelWarn)
	outPut(w.ctx, l.prefix, l.Writer, LevelWarn, strings.TrimSpace(fmt.Sprintln(args...))+w.kvToJson())
}

func (w *fieldLogger) Warnf(format string, args ...interface{}) {
	l := w.getLoggerByLevel(LevelWarn)
	outPut(w.ctx, l.prefix, l.Writer, LevelWarn, fmt.Sprintf(format, args...)+w.kvToJson())
}

func (w *fieldLogger) Error(args ...interface{}) {
	l := w.getLoggerByLevel(LevelError)
	outPut(w.ctx, l.prefix, l.Writer, LevelError, strings.TrimSpace(fmt.Sprintln(args...))+w.kvToJson())
}

func (w *fieldLogger) Errorf(format string, args ...interface{}) {
	l := w.getLoggerByLevel(LevelError)
	outPut(w.ctx, l.prefix, l.Writer, LevelError, fmt.Sprintf(format, args...)+w.kvToJson())
}

var outBufPool = sync.Pool{New: func() interface{} { return bytes.NewBuffer(make([]byte, 0, 512)) }} // default 512

// stringify 由于value为interface类型 为确保输出符合预期 安全输出。
// 对value进行字符串化， 尤其是一些指针类型。
func stringify(value interface{}) string {
	switch value := value.(type) {
	case string:
		// json类型的字符串
		if strings.Contains(value, "\n") {
			return fmt.Sprintf("%q", value) // 防止返回内容有换行
		}
		return value
		// 生支持json的输出 去除 JsonStr
	case []byte:
		if bytes.Contains(value, []byte("\n")) {
			return fmt.Sprintf("%q", string(value)) // 防止返回内容有换行
		}
		return string(value)
	case fmt.Stringer:
		return value.String()
	default:
		outBuf := outBufPool.Get().(*bytes.Buffer)
		outBuf.Reset()
		defer func() { outBufPool.Put(outBuf) }()
		encoder := json.NewEncoder(outBuf)
		encoder.SetEscapeHTML(false)
		err := encoder.Encode(value) // 效率和fmt.Sprintf差不多
		if err == nil && outBuf.Len() > 0 {
			// outBuf.Len()-1 去除末尾的换行符 在Encode源码中有
			return string(outBuf.Bytes()[:outBuf.Len()-1])
		} else {
			return fmt.Sprintf(`%+v`, value)
		}
	}
}

type Name string
type Logger struct {
	defaultInfoLogger  *logger
	defaultWarnLogger  *logger
	defaultErrorLogger *logger
	chanPrintTask      chan *msgWithLogger
	logMap             map[Name]*loggerWithLevel
	wait               sync.WaitGroup
	closed             atomic.Bool // false: open, true: closed
	async              atomic.Bool //default false, if true, write log async
	hook               func(ctx context.Context, hookRecord *HookRecord)
}

// HookRecord file string, line int, function string, level, content string, stack string
type HookRecord struct {
	File     string
	Line     int
	Function string
	Level    Level
	Content  string
	Stack    string
	TraceId  string
}
type msgWithLogger struct {
	writer io.Writer // writer should support multi-thread
	msg    *[]byte
}
type logger struct {
	io.Writer        // destination for output
	prefix    string // prefix on each line to identify the logger (but see Lmsgprefix)
}

// SetHook set hook function
func SetHook(hook func(ctx context.Context, hookRecord *HookRecord)) {
	defaultLogger.hook = hook
}

type Level string

const (
	LevelInfo  Level = "INFO"
	LevelError Level = "ERROR"
	LevelWarn  Level = "WARN"
)

type loggerWithLevel struct {
	infoLogger  *logger
	errorLogger *logger
	warnLogger  *logger
}

var defaultLogger *Logger

type Option struct {
	LogName Name
	Logger  *lumberjack.Logger
}

func callerStack(skip int) []byte {
	buf := new(bytes.Buffer)
	for i := skip + 1; ; i++ {
		pc, file, line, ok := runtime.Caller(i)
		if !ok {
			break
		}
		if _, err := fmt.Fprintf(buf, "%s:%d (0x%x)\n", file, line, pc); err != nil {
			break
		}
	}
	return buf.Bytes()
}

const timeFormat = "2006-01-02T15:04:05.000"

func outPut(ctx context.Context, prefix string, writer io.Writer, level Level, content string) {
	// [REQUEST] [INFO] 2024/07/11 22:04:11.350992 httpcli.go:210: main.main traceId <content>
	pc := make([]uintptr, 2)
	const skip = 3
	_ = runtime.Callers(skip, pc)
	frame := runtime.CallersFrames(pc)
	var file, function string
	var line int
	if f, ok := frame.Next(); ok {
		function = f.Function[strings.LastIndex(f.Function, "/")+1:]
		file = filepath.Base(f.File)
		line = f.Line
	}
	buf := getBuffer()
	// Dont putBuffer(buf) until the task is done
	ctxValue, _ := ctx.Value(TraceIdKey).(string)
	*buf = append([]byte(fmt.Sprintf(
		"%s[%s] %s %s:%d %s traceId:%+v ",
		prefix, level, time.Now().Format(timeFormat), file, line, function, ctxValue)),
		content...)
	if len(*buf) == 0 || (*buf)[len(*buf)-1] != '\n' {
		*buf = append(*buf, '\n')
	}
	if defaultLogger.async.Load() && !defaultLogger.closed.Load() {
		defaultLogger.chanPrintTask <- &msgWithLogger{
			writer: writer,
			msg:    buf,
		}
		//we call hook after write to file by order
		if hook := defaultLogger.hook; hook != nil {
			stack := string(callerStack(skip))
			hookRecord := &HookRecord{
				File:     file,
				Line:     line,
				Function: function,
				Level:    level,
				Content:  content,
				Stack:    stack,
				TraceId:  ctxValue,
			}
			hook(ctx, hookRecord)
		}
		return
	}
	// closed
	writer.Write(*buf)
	//we call hook after write to file by order
	if hook := defaultLogger.hook; hook != nil {
		stack := string(callerStack(skip))
		hookRecord := &HookRecord{
			File:     file,
			Line:     line,
			Function: function,
			Level:    level,
			Content:  content,
			Stack:    stack,
			TraceId:  ctxValue,
		}
		hook(ctx, hookRecord)
	}
	putBuffer(buf)
}

var bufferPool = sync.Pool{New: func() any { return new([]byte) }}

func getBuffer() *[]byte {
	p := bufferPool.Get().(*[]byte)
	*p = (*p)[:0]
	return p
}

func putBuffer(p *[]byte) {
	// Proper usage of a sync.Pool requires each entry to have approximately
	// the same memory cost. To obtain this property when the stored type
	// contains a variably-sized buffer, we add a hard limit on the maximum buffer
	// to place back in the pool.
	//
	// See https://go.dev/issue/23199
	if cap(*p) > 64<<10 {
		*p = nil
	}
	bufferPool.Put(p)
}

// Println logs to the INFO log.
func Println(args ...any) {
	l := defaultLogger.defaultInfoLogger
	outPut(context.Background(), l.prefix, l.Writer, LevelInfo, fmt.Sprintln(args...))
}

// Printf logs to the INFO log.
func Printf(format string, args ...any) {
	l := defaultLogger.defaultInfoLogger
	outPut(context.Background(), l.prefix, l.Writer, LevelInfo, fmt.Sprintf(format, args...))
}

func init() {
	defaultLogger = &Logger{
		defaultInfoLogger:  &logger{Writer: os.Stdout, prefix: ""},
		defaultErrorLogger: &logger{Writer: os.Stderr, prefix: ""},
		defaultWarnLogger:  &logger{Writer: os.Stderr, prefix: ""},
		logMap:             make(map[Name]*loggerWithLevel),
		chanPrintTask:      make(chan *msgWithLogger, 64),
	}
	defaultLogger.wait.Add(1)
	go func() {
		defer defaultLogger.wait.Done()
		for {
			select {
			case task, ok := <-defaultLogger.chanPrintTask:
				if !ok {
					return
				}
				msg := task.msg
				task.writer.Write(*task.msg)
				putBuffer(msg)
			}
		}
	}()
}
