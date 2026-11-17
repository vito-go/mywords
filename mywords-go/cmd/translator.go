package main

import "C"
import (
	"encoding/json"
	"mywords/pkg/translator"
)

//export Translate
func Translate(textC *C.char) *C.char {

	return translateNotImplemented(textC)
}

func translateNotImplemented(textC *C.char) *C.char {
	result := translator.Translation{
		ErrCode:   500,
		ErrMsg:    "Error: the feature of translation is still under development. Please open an issue at https://github.com/vito-go/mywords/issues.",
		Result:    "",
		PoweredBy: "mywords",
	}
	b, _ := json.Marshal(result)
	return C.CString(string(b))
}
