package main

import (
	"embed"
	"io/fs"
	"path/filepath"
)

type webEmbedHandler struct {
	webEmbed embed.FS
}

func (f webEmbedHandler) Open(name string) (fs.File, error) {
	// 在windows系统下必须用toSlash 封装一下路径，否则，web\index.html!=web/index.html
	name = filepath.ToSlash(filepath.Join("web", name))
	return f.webEmbed.Open(name)
}
