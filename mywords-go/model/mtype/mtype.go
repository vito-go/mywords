package mtype

type KeyId int

const (
	KeyIdProxy           = 1 // value, http or https or socks5, auth or not
	KeyIdShareInfo       = 2 //  ShareInfo
	KeyIdDefaultDictPath = 3 // default dict path
)

type KeyValueInfo struct {
	ShareInfo ShareInfo
	Proxy     string
}
