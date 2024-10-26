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
		ErrMsg:    "Error: the feature of translation is still under development. Please contact the developer 56462631+vito-go@users.noreply.github.com.",
		Result:    "",
		PoweredBy: "mywords",
	}
	b, _ := json.Marshal(result)
	return C.CString(string(b))
}
