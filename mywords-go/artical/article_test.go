package artical

import (
	"testing"
)

func TestParseSourceUrl(t *testing.T) {
	sourceURL := "https://cn.nytimes.com/china/20240911/china-us-woman-imprisoned/zh-hant/dual/"
	art, err := ParseSourceUrl(sourceURL, DefaultXpathExpr, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%+v", art)
}
