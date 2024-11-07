package sources

import (
	"fmt"
	"testing"
)

func TestGetSources(t *testing.T) {
	fmt.Println("TestGetSources")
	sourceURLs, err := GetSources(nil)
	if err != nil {
		t.Error(err)
	}
	t.Log(sourceURLs)
}
