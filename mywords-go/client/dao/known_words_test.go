package dao

import (
	"context"
	"mywords/pkg/db"
	"testing"
)

func Test_knownWordsDao_UpdateOrCreate(t *testing.T) {
	gdb, err := db.NewDB("/home/liushihao/.local/share/com.example.mywords/db/myproxy.db")
	if err != nil {
		panic(err)
	}
	allDao := AllDao{
		gdb:           gdb,
		FileInfoDao:   nil,
		KeyValueDao:   nil,
		DictInfoDao:   nil,
		KnownWordsDao: &knownWordsDao{Gdb: gdb},
	}
	err = allDao.KnownWordsDao.UpdateOrCreate(context.Background(), "test", 1)
	if err != nil {
		t.Fatal(err)
	}
}

// ShowCreateTable
func Test_knownWordsDao_ShowCreateTable(t *testing.T) {
	gdb, err := db.NewDB("/home/liushihao/.local/share/com.example.mywords/db/myproxy.db")
	if err != nil {
		panic(err)
	}
	allDao := AllDao{
		gdb:           gdb,
		FileInfoDao:   nil,
		KeyValueDao:   nil,
		DictInfoDao:   nil,
		KnownWordsDao: &knownWordsDao{Gdb: gdb},
	}
	result, err := allDao.KnownWordsDao.ShowCreateTable(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	t.Log(result)
}
