package flutterlog

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
)

type Logger struct {
	url      string
	logNonce string
	// logChan must be asynchronous, otherwise it will deadlock, cannot use []byte,
	// otherwise due to the existence of outPool, it will lead to duplicate or lost/misplaced log data
	ctx       context.Context
	closeFunc context.CancelFunc // ensure only close once
	logChan   chan string
}

func NewLogger(url string, nonce string) *Logger {
	ctx, cancel := context.WithCancel(context.Background())
	f := &Logger{
		url:       url,
		logNonce:  nonce,
		logChan:   make(chan string, 1024),
		ctx:       ctx,
		closeFunc: cancel,
	}
	//go func() {
	//	for s := range f.logChan {
	//		f.write(s)
	//	}
	//}()
	// we show not write like above, because we want to avoid to send log to flutter when channel is closed
	go func() {
		for {
			select {
			case <-f.ctx.Done():
				return
			case s := <-f.logChan:
				f.write(s)
			}
		}
	}()
	return f
}

// Close .
func (f *Logger) Close() {
	f.closeFunc()
	// close(f.logChan) we should not close logChan to avoid to send log to flutter when channel is closed
}

func (f *Logger) Write(content []byte) (int, error) {
	msg := string(content)
	// avoid to send log to flutter when channel is closed
	select {
	case <-f.ctx.Done():
		return 0, errors.New("logger was closed")
	default:

	}
	select {
	case f.logChan <- msg:
	default:
		return 0, errors.New("log chanel is full")
		// if logChan is full, discard the log
	}
	return len(msg), nil
}

func (f *Logger) write(content string) (int, error) {
	method := "POST"
	payload := strings.NewReader(content)
	client := &http.Client{}
	defer client.CloseIdleConnections()
	req, err := http.NewRequest(method, f.url, payload)
	if err != nil {
		return 0, err
	}
	req.Header.Add("Content-Type", "text/plain")
	req.Header.Add("X-Log-Nonce", f.logNonce)
	// X-Log-Nonce: used to identify the log source
	response, err := client.Do(req)
	if err != nil {
		return 0, err
	}
	defer response.Body.Close()
	_, _ = io.Copy(io.Discard, response.Body)
	return len(content), nil
}
