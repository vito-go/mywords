package dict

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

type MultiDictZip struct {
	mux           sync.Mutex
	rootDataDir   string //app data dir
	dictIndexInfo *dictIndexInfo
	runPort       int
	onceInit      sync.Once
}

func (m *MultiDictZip) saveInfo() error {
	b, _ := json.MarshalIndent(m.dictIndexInfo, "", "  ")
	err := os.WriteFile(filepath.Join(m.rootDataDir, appDictDir, dictInfoJson), b, 0644)
	return err
}

type dictIndexInfo struct {
	DictZip              *DictZip          `json:"-"` // DefaultDictBasePath　不为空才可以
	DefaultDictBasePath  string            `json:"defaultDictBasePath,omitempty"`
	DictBasePathTitleMap map[string]string `json:"dictBasePathTitleMap,omitempty"` //zipFile:name
}

func NewMultiDictZip(rootDataDir string) *MultiDictZip {
	rootDataDir = filepath.ToSlash(rootDataDir)
	m := MultiDictZip{
		mux:         sync.Mutex{},
		rootDataDir: rootDataDir,
		runPort:     0,
		onceInit:    sync.Once{},
		dictIndexInfo: &dictIndexInfo{
			DefaultDictBasePath:  "",
			DictZip:              nil,
			DictBasePathTitleMap: make(map[string]string),
		},
	}
	return &m
}

func (m *MultiDictZip) GetBaseUrl() string {
	u := fmt.Sprintf("http://localhost:%d", m.runPort)
	return u
}
func (m *MultiDictZip) GetDefaultDict() string {
	return m.dictIndexInfo.DefaultDictBasePath
}
func (m *MultiDictZip) GetHTMLRenderContentByWord(word string) (string, error) {
	d := m.dictIndexInfo.DictZip
	if d == nil {
		return "", nil
	}
	return d.GetHTMLRenderContentByWord(word)

}
func (m *MultiDictZip) GetUrlByWord(word string) (string, bool) {
	m.mux.Lock()
	defer m.mux.Unlock()
	runPort := m.runPort
	if runPort == 0 {
		return "", false
	}
	d := m.dictIndexInfo.DictZip
	if d == nil {
		return "", false
	}
	htmlPath, ok := d.FinalHtmlBasePathWithOutHtml(word)
	if !ok {
		return "", false
	}
	u := fmt.Sprintf("http://localhost:%d/%s.html?word=%s", m.runPort, htmlPath, url.QueryEscape(word))
	return u, true
}

func (m *MultiDictZip) FinalHtmlBasePathWithOutHtml(word string) (string, bool) {
	m.mux.Lock()
	defer m.mux.Unlock()
	runPort := m.runPort
	if runPort == 0 {
		return "", false
	}
	d := m.dictIndexInfo.DictZip
	if d == nil {
		return "", false
	}
	htmlPath, ok := d.FinalHtmlBasePathWithOutHtml(word)
	if !ok {
		return "", false
	}
	return htmlPath, true
}

func (m *MultiDictZip) DictBasePathTitleMap() map[string]string {
	m.mux.Lock()
	defer m.mux.Unlock()
	result := make(map[string]string, len(m.dictIndexInfo.DictBasePathTitleMap))
	for k, v := range m.dictIndexInfo.DictBasePathTitleMap {
		result[k] = v
	}
	return result
}
func (m *MultiDictZip) UpdateDictName(basePath, title string) error {
	m.mux.Lock()
	defer m.mux.Unlock()
	_, ok := m.dictIndexInfo.DictBasePathTitleMap[basePath]
	if !ok {
		return errors.New("字典不存在")
	}
	m.dictIndexInfo.DictBasePathTitleMap[basePath] = title
	if err := m.saveInfo(); err != nil {
		return err
	}
	return nil
}
func (m *MultiDictZip) SetDefaultDict(basePath string) error {
	m.mux.Lock()
	defer m.mux.Unlock()
	if m.dictIndexInfo.DefaultDictBasePath == basePath {
		return nil
	}
	if basePath == "" {
		if d := m.dictIndexInfo.DictZip; d != nil {
			d.Close()
		}
		m.runPort = 0
		m.dictIndexInfo.DefaultDictBasePath = basePath
		m.dictIndexInfo.DictZip = nil
		if err := m.saveInfo(); err != nil {
			return err
		}
		return nil
	}
	zipFile := filepath.Join(m.rootDataDir, appDictDir, basePath)
	d, err := NewDictZip(zipFile)
	if err != nil {
		return err
	}
	if oldDict := m.dictIndexInfo.DictZip; oldDict != nil {
		oldDict.Close()
	}
	m.dictIndexInfo.DictBasePathTitleMap[basePath] = basePath
	if err = m.saveInfo(); err != nil {
		return err
	}
	m.dictIndexInfo.DictZip = d

	var chanErr chan error
	go func() {
		var err error
		if err = d.start(); err != nil {
			chanErr <- err
		}
	}()
	select {
	case err = <-chanErr:
		return err
	case <-time.After(time.Millisecond * 200):
		if d.port == 0 {
			return errors.New("start error. time out")
		}
		m.runPort = d.port
		m.dictIndexInfo.DefaultDictBasePath = basePath
		if err = m.saveInfo(); err != nil {
			return err
		}
		return nil
	}

}
func (m *MultiDictZip) DelDict(basePath string) error {
	m.mux.Lock()
	defer m.mux.Unlock()
	if basePath == m.dictIndexInfo.DefaultDictBasePath {
		m.dictIndexInfo.DefaultDictBasePath = ""
		d := m.dictIndexInfo.DictZip
		d.Close()
		m.dictIndexInfo.DictZip = nil
		m.runPort = 0
	}

	delete(m.dictIndexInfo.DictBasePathTitleMap, basePath)
	if err := m.saveInfo(); err != nil {
		return err
	}
	os.Remove(filepath.Join(m.rootDataDir, appDictDir, basePath))
	return nil
}
func (m *MultiDictZip) AddDict(originalZipPath string) error {
	m.mux.Lock()
	defer m.mux.Unlock()
	_, ok := m.dictIndexInfo.DictBasePathTitleMap[filepath.Base(originalZipPath)]
	if ok {
		return fmt.Errorf("该字典已加载: %s", filepath.Base(originalZipPath))
	}
	zipFile := filepath.Join(m.rootDataDir, appDictDir, filepath.Base(originalZipPath))
	err := copyFile(zipFile, originalZipPath)
	if err != nil {
		return err
	}
	basePath := filepath.Base(zipFile)
	d, err := NewDictZip(zipFile)
	if err != nil {
		return err
	}
	m.dictIndexInfo.DictBasePathTitleMap[basePath] = basePath
	if err = m.saveInfo(); err != nil {
		return err
	}
	if len(m.dictIndexInfo.DictBasePathTitleMap) == 1 || m.runPort == 0 {
		var chanErr chan error
		go func() {
			var err error
			if err = d.start(); err != nil {
				chanErr <- err
			}
		}()
		select {
		case err = <-chanErr:
			return err
		case <-time.After(time.Millisecond * 200):
			if d.port == 0 {
				return errors.New("start error. time out")
			}
			m.runPort = d.port
			m.dictIndexInfo.DefaultDictBasePath = filepath.Base(zipFile)
			m.dictIndexInfo.DictZip = d
			if err = m.saveInfo(); err != nil {
				return err
			}
			return nil
		}
	}
	return err
}
func (m *MultiDictZip) SearchByKeyWord(keyWord string) []string {
	m.mux.Lock()
	defer m.mux.Unlock()
	d := m.dictIndexInfo.DictZip
	if d == nil {
		return nil
	}
	return SearchByKeyWord(keyWord, d.allWordHtmlFileMap)
}

func (m *MultiDictZip) Init() {
	m.onceInit.Do(func() {
		m.mux.Lock()
		defer m.mux.Unlock()
		err := os.MkdirAll(filepath.Join(m.rootDataDir, appDictDir), 0755)
		if err != nil {
			return
		}
		var allPaths []string
		err = filepath.WalkDir(filepath.Join(m.rootDataDir, appDictDir), func(path string, d fs.DirEntry, err error) error {
			if d.Name() == dictInfoJson || strings.HasSuffix(d.Name(), ".zip") {
				allPaths = append(allPaths, path)
			}
			return nil
		})
		if err != nil {
			return
		}
		var info dictIndexInfo
		b, err := os.ReadFile(filepath.Join(m.rootDataDir, appDictDir, dictInfoJson))
		if err != nil {
			return
		}
		if len(b) > 0 {
			err = json.Unmarshal(b, &info)
			if err != nil {
				return
			}
		}
		if len(info.DictBasePathTitleMap) == 0 {
			return
		}
		m.dictIndexInfo = &info
		if m.dictIndexInfo.DefaultDictBasePath != "" {
			path := filepath.Join(m.rootDataDir, appDictDir, m.dictIndexInfo.DefaultDictBasePath)
			d, err := NewDictZip(path)
			if err != nil {
				return
			}
			m.dictIndexInfo.DictZip = d
			var chanErr chan error
			go func() {
				var err error
				if err = d.start(); err != nil {
					chanErr <- err
				}
			}()
			select {
			case err = <-chanErr:
				return
			case <-time.After(time.Millisecond * 200):
				if d.port == 0 {
					return
				}
				m.runPort = d.port
				return
			}
		}
	})
}
func copyFile(tar, src string) error {
	fw, err := os.Create(tar)
	if err != nil {
		return err
	}
	defer fw.Close()
	fr, err := os.Open(src)
	if err != nil {
		os.Remove(tar)
		return err
	}
	defer fr.Close()
	_, err = io.Copy(fw, fr)
	if err != nil {
		return err
	}
	return nil
}
