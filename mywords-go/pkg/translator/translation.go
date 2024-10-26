package translator

type Translation struct {
	ErrCode   int    `json:"errCode"` // 0 success
	ErrMsg    string `json:"errMsg"`  //
	Result    string `json:"result"`
	PoweredBy string `json:"poweredBy"`
}
