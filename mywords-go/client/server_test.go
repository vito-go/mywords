package client

import (
	"os"
	"path/filepath"
	"testing"
)

var clientGlobal *Client

func init() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	rootDataDir := filepath.ToSlash(filepath.Join(homeDir, ".local/share/com.example.mywords"))
	clientGlobal, err = NewClient(rootDataDir)
	if err != nil {
		panic(err)
	}
}
func TestClient_ReparseArticleFileInfo(t *testing.T) {
	art, err := clientGlobal.ReparseArticleFileInfo(1)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%+v", art.NetCount)
}

// TestClient_ReparseArticleFileInfo is a unit test function.
func TestClient_AllTables(t *testing.T) {
	var tables []string
	err := clientGlobal.gdb.Raw("SELECT name FROM sqlite_master WHERE type='table';").Find(&tables).Error
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%+v", tables)
}

// AllWordsByCreateDayWithIdDesc
func TestClient_AllWordsByCreateDayWithIdDesc(t *testing.T) {
	words, err := clientGlobal.AllDao().KnownWordsDao.AllWordsByCreateDayWithIdDesc(ctx, 0)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%+v", words)
}

// restoreFileInfoFromArchived
func TestClient_restoreFileInfoFromArchived(t *testing.T) {
	err := clientGlobal.restoreFileInfoFromArchived()
	if err != nil {
		t.Fatal(err)
	}
}

// restoreFileInfoFromNotArchived
func TestClient_restoreFileInfoFromNotArchived(t *testing.T) {
	err := clientGlobal.restoreFileInfoFromNotArchived()
	if err != nil {
		t.Fatal(err)
	}
}

// reParseArticleFileInfo
func TestClient_reParseArticleFileInfo(t *testing.T) {
	art, err := clientGlobal.ReparseArticleFileInfo(10)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%+v", art)
}
