package client

import (
	"context"
	"mywords/pkg/log"
	"net"
	"net/http"
)
import _ "net/http/pprof"

func (c *Client) startPProf() (net.Listener, error) {
	// listen on random port
	ln, err := net.Listen("tcp", ":0")
	if err != nil {
		return nil, err // log.Println("start pprof failed")
	}
	http.HandleFunc("/flutter/setState", func(w http.ResponseWriter, r *http.Request) {
		c.SendCodeContent(CodeNotifyNotifyOnly, "setState")
	})
	srv := &http.Server{Handler: http.DefaultServeMux}
	go func() {
		err = srv.Serve(ln)
		if err != nil {
			log.Ctx(context.Background()).Error(err.Error())
		}
	}()
	log.Println("pprof client is running on", ln.Addr().String())
	return ln, nil
}
