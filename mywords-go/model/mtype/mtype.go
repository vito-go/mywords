package mtype

type KeyId int

const (
	KeyIdProxy         = 1 // value, http or https or socks5, auth or not
	KeyIdShareInfo     = 2 //  ShareInfo
	KeyIdDefaultDictId = 3 // default dict id
	WebOnlineClose     = 4 //
)

type KeyValueInfo struct {
	ShareInfo ShareInfo
	Proxy     string
}
