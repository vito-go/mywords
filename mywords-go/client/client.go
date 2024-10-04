package client

import (
	"context"
	"crypto/md5"
	"errors"
	"fmt"
	"golang.org/x/time/rate"
	"gorm.io/gorm"
	"io"
	"mywords/artical"
	"mywords/client/dao"
	"mywords/dict"
	"mywords/model"
	"mywords/model/mtype"
	"mywords/pkg/db"
	"mywords/pkg/log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

const (
	dbDir   = "db"
	dictDir = "dict" // zip 文件格式

	dbName = "mywords.db"
)

type Client struct {
	rootDataDir string
	xpathExpr   string //must can compile
	//knownWordsMap map[string]map[string]WordKnownLevel // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//fileInfoMap1        map[string]FileInfo                  // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}

	mux         sync.Mutex //
	shareServer *http.Server
	shareOpened atomic.Bool
	// multicast

	//chartDateLevelCountMap map[string]map[WordKnownLevel]map[string]struct{} // date: {1: {"words":{}}, 2: 200, 3: 300}

	// 新字段

	rootDir string

	gdb             *gorm.DB
	dbPath          string
	allDao          *dao.AllDao
	codeContentChan chan CodeContent
	pprofListen     net.Listener //may be nil

	messageLimiter *rate.Limiter
	closed         atomic.Bool
	oneDict        *dict.OneDict
	defaultDictId  *atomic.Int64
	//		//
	//	//knownWordsMap map[string]map[string]WordKnownLevel // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//	knownWordsMap *MySyncMapMap[string, WordKnownLevel] // a: apple:1, ant:1, b: banana:2, c: cat:1 ...
	//	//fileInfoMap1        map[string]FileInfo                  // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//	fileInfoMap         *MySyncMap[FileInfo] // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//	fileInfoArchivedMap *MySyncMap[FileInfo] // a.txt: FileInfo{FileName: a.txt, Size: 1024, LastModified: 123456, IsDir: false, TotalCount: 100, NetCount: 50}
	//
	//	mux           sync.Mutex //
	//	shareListener net.Listener
	//	// multicast
	//	remoteHostMap sync.Map // remoteHost: port
	//
	//	//chartDateLevelCountMap map[string]map[WordKnownLevel]map[string]struct{} // date: {1: {"words":{}}, 2: 200, 3: 300}
	//	chartDateLevelCountMap *MySyncMapMap[WordKnownLevel, map[string]struct{}] // date: {1: {"words":{}}, 2: 200, 3: 300}
	//dictRunPort int64 // -1 means not to start the dictionary service, 0 means random port, >0 means specified port
	webDict *dict.WebDict
}

// WebDictRunPort .
func (c *Client) WebDictRunPort() int {
	return c.webDict.RunPort()
}

// NewClient rootDataDir is where to store data,
// dictRunPort: dictionary service port, -1 means not to start the dictionary service, 0 means random port, >0 means specified port
func NewClient(rootDataDir string, dictPort int) (*Client, error) {
	// 获取平台 GOOS
	rootDataDir = filepath.ToSlash(rootDataDir)
	if err := os.MkdirAll(rootDataDir, 0755); err != nil {
		return nil, err
	}
	dbDirPath := filepath.ToSlash(filepath.Join(rootDataDir, dbDir))
	log.Printf("Create db path: %s", dbDirPath)
	err := os.MkdirAll(dbDirPath, os.ModePerm)
	if err != nil {
		return nil, err
	}
	log.Printf("Create dict dir: %s", dictDir)
	dictDirPath := filepath.ToSlash(filepath.Join(rootDataDir, dictDir))
	err = os.MkdirAll(dictDirPath, os.ModePerm)
	if err != nil {
		return nil, err
	}
	dbPath := filepath.ToSlash(filepath.Join(dbDirPath, dbName))
	gdb, err := db.NewDB(dbPath)
	if err != nil {
		return nil, err
	}
	err = InitCreateTables(gdb)
	if err != nil {
		return nil, err
	}

	allDao := dao.NewAllDao(gdb)
	if err := os.MkdirAll(filepath.Join(rootDataDir, dataDir, gobFileDir), 0755); err != nil {
		return nil, err
	}
	onDict := dict.NewOneDict()
	webDict, err := dict.NewWebDict(onDict, dictPort)
	if err != nil {
		return nil, err
	}
	defaultDictIdAtomic := &atomic.Int64{}
	client := &Client{
		rootDataDir:     rootDataDir,
		xpathExpr:       artical.DefaultXpathExpr,
		allDao:          allDao,
		rootDir:         rootDataDir,
		gdb:             gdb,
		dbPath:          dbPath,
		codeContentChan: make(chan CodeContent, 1024),
		shareOpened:     atomic.Bool{},
		oneDict:         onDict,
		webDict:         webDict,
		defaultDictId:   defaultDictIdAtomic,
		//dictRunPort:     atomic.Int64{},
	}

	defaultDictId, _ := allDao.KeyValueDao.DefaultDictId(ctx)
	defaultDictIdAtomic.Store(defaultDictId)
	if defaultDictId > 0 {
		go func() {
			err := client.SetDefaultDictById(ctx, defaultDictId)
			if err != nil {
				log.Ctx(ctx).Error(err.Error())
				return
			}
		}()
	}
	pprofLis, err := client.startPProf()
	if err != nil {
		return nil, err
	}
	client.pprofListen = pprofLis
	log.SetHook(func(ctx context.Context, record *log.HookRecord) {
		msg := record.Content
		if !debug.Load() {
			if runtime.GOOS == "android" || runtime.GOOS == "ios" {
				client.SendCodeContent(CodeLog, msg)
			}
		}
		level := record.Level

		if level == log.LevelError {

		} else if level == log.LevelWarn {

		}

	})
	return client, nil
}

// DefaultDictId .
func (c *Client) DefaultDictId() int64 {
	return c.defaultDictId.Load()
}
func (c *Client) OneDict() *dict.OneDict {
	return c.oneDict
}

func (c *Client) DelDict(ctx context.Context, id int64) error {
	if id == 0 {
		return nil
	}
	c.mux.Lock()
	defer c.mux.Unlock()
	dictInfo, err := c.allDao.DictInfoDao.ItemById(ctx, id)
	if err != nil {
		return err
	}
	row, err := c.allDao.DictInfoDao.DeleteById(ctx, id)
	if err != nil {
		return err
	}
	if row == 0 {
		return nil
	}
	_ = os.Remove(dictInfo.Path)
	c.oneDict.Close()
	if c.defaultDictId.Load() == id {
		_ = c.allDao.KeyValueDao.UpdateOrCreateByKeyId(ctx, mtype.KeyIdDefaultDictId, "0")
		c.defaultDictId.Store(0)
	}
	return nil
}
func (c *Client) SetDefaultDictById(ctx context.Context, id int64) error {
	c.mux.Lock()
	c.mux.Unlock()
	if id <= 0 {
		c.defaultDictId.Store(0)
		// 设置的默认的词典
		c.OneDict().Close()
		return nil
	}
	dictInfo, err := c.allDao.DictInfoDao.ItemById(ctx, id)
	if err != nil {
		return err
	}
	err = c.oneDict.SetDict(dictInfo.Path)
	if err != nil {
		return err
	}
	c.defaultDictId.Store(id)
	_ = c.allDao.KeyValueDao.UpdateOrCreateByKeyId(ctx, mtype.KeyIdDefaultDictId, fmt.Sprintf("%d", id))
	return nil
}
func (c *Client) GetTargetPathAndCheckExist(zipPath string) (targetPath string, exist bool, err error) {
	// copy to targetPath
	f, err := os.Open(zipPath)
	if err != nil {
		return "", false, err
	}
	defer f.Close()
	h := md5.New()
	fileSize, err := io.Copy(h, f)
	if err != nil {
		return "", false, err
	}
	sum := h.Sum(nil)
	// copy dict
	targetPath = filepath.Join(c.rootDir, dictDir, fmt.Sprintf("%x.zip", sum))
	targetInfo, err := os.Stat(targetPath)
	if err != nil {
		return targetPath, false, nil
	}
	if targetInfo.IsDir() {
		err = os.Remove(targetPath)
		if err != nil {
			return "", false, err
		}
		return targetPath, false, nil
	}
	if targetInfo.Size() != fileSize {
		if err = os.Remove(targetPath); err != nil {
			return "", false, err
		}
		return targetPath, false, nil
	}
	return targetPath, true, nil
}
func (c *Client) AddDict(ctx context.Context, zipPath string) error {
	name := strings.TrimSuffix(filepath.Base(zipPath), ".zip")
	return c.AddDictWithName(ctx, zipPath, name)
}
func (c *Client) AddDictWithName(ctx context.Context, zipPath string, name string) error {
	c.mux.Lock()
	c.mux.Unlock()
	statusInfo, err := os.Stat(zipPath)
	if err != nil {
		return err
	}
	if statusInfo.IsDir() {
		return errors.New("zipPath is dir")
	}
	// copy dict
	targetPath, exist, err := c.GetTargetPathAndCheckExist(zipPath)
	if err != nil {
		return err
	}
	log.Println("targetPath", targetPath, "exist", exist)
	if !exist {
		if err = copyFile(zipPath, targetPath); err != nil {
			return err
		}
	}
	log.Println("准备设置词典", targetPath)
	err = c.oneDict.SetDict(targetPath)
	if err != nil {
		os.Remove(targetPath)
		return err
	}
	// DictInfo 单词字典信息
	// name ,path, createAt, updateAt, size
	now := time.Now().UnixMilli()
	dictInfo := model.DictInfo{
		ID:       0,
		Name:     name,
		Path:     targetPath,
		CreateAt: now,
		UpdateAt: now,
		Size:     statusInfo.Size(),
	}
	id, err := c.allDao.DictInfoDao.Create(ctx, &dictInfo)
	if err != nil {
		c.oneDict.Close()
		return err
	}
	log.Println("add dict success", id)
	c.defaultDictId.Store(id)
	return nil
}

func copyFile(src, dst string) error {
	log.Println("copyFile", "src", src, "dst", dst)
	if runtime.GOOS == "android" || runtime.GOOS == "ios" {
		// 直接移动
		log.Println("移动 android move file", "src", src, "dst", dst)
		//defer func() {
		//	if err := os.Remove(src); err != nil {
		//		log.Println("Android copyfile remove file error", err)
		//	}
		//}()
		// 移动平台直接移动文件
		err := os.Rename(src, dst)
		if err != nil {
			return err
		}
		log.Printf("runtime.GOOS: %s, copyFile success, src: %s, dst: %s", runtime.GOOS, src, dst)
		return nil
	}
	fw, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer fw.Close()
	// copy to targetPath
	f, err := os.Open(src)
	if err != nil {
		return err
	}
	defer f.Close()
	if _, err = io.Copy(fw, f); err != nil {
		return err
	}
	log.Println("copyFile success", "src", src, "dst", dst)
	return nil
}
