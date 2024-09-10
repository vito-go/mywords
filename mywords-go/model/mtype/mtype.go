package mtype

type KeyId int

const (
	KeyIdProxy     = 1 // value, http or https or socks5, auth or not
	KeyIdShareInfo = 2 // value, http or https or socks5, auth or not
)
