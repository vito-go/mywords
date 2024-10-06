package client

import (
	"context"
	"encoding/json"
	"fmt"
	"golang.org/x/time/rate"
	"mywords/pkg/ratelimit"
	"strconv"
	"strings"
	"time"
)

// contentType int,

// 0 Error
// 1 Message

const (
	CodeError           = 0
	CodeUpdateKnowWords = 1
	CodeMessageError    = 2
	CodeMessageWarn     = 3

	CodeWsConnectStatus = 20 // data is int , 0 ready, 1 connecting, 2 connected, 3 failed , 4 closed
	CodeReadFromDB      = 30 //

	CodeNotifyNotifyOnly = 100 //
	CodeNotifyForever    = 101

	// debug for more than 1000

	CodeLog = 1000
)

var codeLimiterMap = map[int64]*ratelimit.LimiterInfo{
	CodeReadFromDB: {
		Limiter:   rate.NewLimiter(rate.Every(time.Second), 1),
		LimitWait: false,
	},
	CodeMessageError: {
		Limiter:   rate.NewLimiter(rate.Every(time.Minute*5)*2, 1),
		LimitWait: false,
	},
	CodeMessageWarn: {
		Limiter:   rate.NewLimiter(rate.Every(time.Minute*5), 1),
		LimitWait: false,
	},
}

// SendCodeContent .
func (c *Client) SendCodeContent(code int64, content any) {
	if limit, ok := codeLimiterMap[code]; ok {
		if err := limit.Limit(context.Background()); err != nil {
			return
		}
	}
	// don't print log, it will cause deadlock, because the log may call this function with hook
	c.codeContentChan <- CodeContent{Code: code, Content: content}
}

// ReadMessage returns a channel of messages, blocking until a message is available.
// return code:content,  0:Error, 1:Message
// content is a json string
func (c *Client) ReadMessage() string {
	var builder strings.Builder
	builderWrite := func(data *CodeContent) {
		builder.WriteString(strconv.FormatInt(data.Code, 10))
		builder.WriteString(":")
		switch v := data.Content.(type) {
		case string:
			builder.WriteString(v)
		case []byte:
			builder.Write(v)
		case bool, int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, uintptr, float32, float64, complex64, complex128:
			builder.WriteString(fmt.Sprintf("%v", v))
		case error:
			builder.WriteString(v.Error())
		case nil:
			builder.WriteString("null")
		case *string:
			builder.WriteString(*v)
		case *[]byte:
			builder.Write(*v)
		default:
			b, _ := json.Marshal(data.Content)
			builder.Write(b)
		}
	}
	data, ok := <-c.codeContentChan
	if !ok {
		builder.WriteString(strconv.FormatInt(CodeError, 10))
		builder.WriteString(":")
		builder.WriteString(ErrMessageChanClosed.Error())
		return builder.String()
	}
	builderWrite(&data)
	return builder.String()

	//select {
	//case data := <-c.codeContentChan:
	//	builderWrite(&data)
	//	return builder.String()
	//case <-time.After(timeout):
	//	builder.WriteString(strconv.FormatInt(0, 10))
	//	builder.WriteString(":")
	//	builder.WriteString(ErrMessageChanTimeout.Error())
	//	return builder.String()
	//}
}
