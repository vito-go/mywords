package log

import (
	"context"
	"testing"
)

type UserInfo struct {
	Name string
}

func TestCtx(t *testing.T) {
	Ctx(context.Background()).WithField("heelo", "world").
		WithFields("nihao", map[string]string{"k1": "v1"},
			"k2", 222, "UserInfo", UserInfo{Name: "dsf"}, 333, "addf", "as").Info("Hello World")
	Ctx(context.Background()).WithField("heelo", "world").
		WithFields("nihao", map[string]string{"k1": "v1"},
			"k2", 222, "UserInfo", UserInfo{Name: "dsf"}, "addf", "as").Infof("Hello World")
}

func TestRandStringBytesMask(t *testing.T) {
	t.Log(RandStringByLen(7))
}

func BenchmarkName(b *testing.B) {
	for i := 0; i < b.N; i++ {
		RandStringByLen(7)
	}
}
func BenchmarkRandomId(b *testing.B) {
	for i := 0; i < b.N; i++ {
		RandomId()
	}
}
