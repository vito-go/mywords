package client

import (
	"encoding/json"
	"mywords/model"
	"mywords/pkg/log"
	"net/url"
	"os"
	"path/filepath"
)

func (c *Client) restoreFileInfoFromArchived() error {
	b, err := os.ReadFile(filepath.Join(c.DataDir(), "file_infos_archived.json"))
	if err != nil {
		return err
	}
	var fileInfosMap map[string]oldFileInfo
	err = json.Unmarshal(b, &fileInfosMap)
	if err != nil {
		return err
	}
	return c.restoreFromOldBy(fileInfosMap, true)
}

func (c *Client) restoreFileInfoFromNotArchived() error {
	b, err := os.ReadFile(filepath.Join(c.DataDir(), "file_infos.json"))
	if err != nil {
		return err
	}
	var fileInfosMap map[string]oldFileInfo
	err = json.Unmarshal(b, &fileInfosMap)
	if err != nil {
		return err
	}
	return c.restoreFromOldBy(fileInfosMap, false)
}

func (c *Client) restoreFromOldBy(fileInfosMap map[string]oldFileInfo, archived bool) error {
	// 从旧版本恢复数据
	// 1. 从旧版本的数据目录中读取数据
	// 2. 将数据写入到新版本的数据目录中
	// 3. 删除旧版本的数据目录
	// 4. 重启服务

	for _, v := range fileInfosMap {
		sourceUrl := v.SourceUrl
		u, err := url.Parse(sourceUrl)
		if err != nil {
			log.Ctx(ctx).Errorf("parse source url failed: %s", sourceUrl)
			continue
		}
		host := u.Host
		_, err = c.allDao.FileInfoDao.ItemBySourceUrl(ctx, sourceUrl)
		if err == nil {
			continue
		}
		filePath := c.gobPathByFileName(v.FileName)
		_, err = os.Stat(filePath)
		if err != nil {
			log.Ctx(ctx).Errorf("file not found: %s", filePath)
			continue
		}
		fileInfo := model.FileInfo{
			ID:         0,
			Title:      v.Title,
			SourceUrl:  v.SourceUrl,
			Host:       host,
			FilePath:   filePath,
			Size:       v.Size,
			TotalCount: v.TotalCount,
			NetCount:   v.NetCount,
			Archived:   archived,
			CreateAt:   v.LastModified,
			UpdateAt:   v.LastModified,
		}
		_, err = c.allDao.FileInfoDao.Create(ctx, &fileInfo)
		if err != nil {
			log.Ctx(ctx).Error(err)
			continue
		}

	}
	return nil
}

type oldFileInfo struct {
	Title        string `json:"title"`
	SourceUrl    string `json:"sourceUrl"`
	FileName     string `json:"fileName"`
	Size         int    `json:"size"`
	LastModified int64  `json:"lastModified"`
	IsDir        bool   `json:"isDir"`
	TotalCount   int    `json:"totalCount"`
	NetCount     int    `json:"netCount"`
}
