package client

import (
	"encoding/json"
	"mywords/model"
	"mywords/model/mtype"
	"mywords/pkg/log"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

func (c *Client) restoreFileInfoFromArchived() error {
	path := filepath.Join(c.DataDir(), "file_infos_archived.json")
	log.Ctx(ctx).Infof("restore file info from archived: %s", path)
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	var fileInfosMap map[string]oldFileInfo
	err = json.Unmarshal(b, &fileInfosMap)
	if err != nil {
		return err
	}
	var oldFileInfos []oldFileInfo
	for _, v := range fileInfosMap {
		oldFileInfos = append(oldFileInfos, v)
	}
	err = c.restoreFromOldBy(oldFileInfos, true)
	if err != nil {
		return err
	}
	log.Ctx(ctx).Infof("restore file info from archived success: %s", path)
	// don't delete file,
	return nil
}

func (c *Client) restoreFileInfoFromNotArchived() error {
	path := filepath.Join(c.DataDir(), "file_infos.json")
	log.Ctx(ctx).Infof("restore file info from not archived: %s", path)
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	var fileInfosMap map[string]oldFileInfo
	err = json.Unmarshal(b, &fileInfosMap)
	if err != nil {
		return err
	}
	var oldFileInfos []oldFileInfo
	for _, v := range fileInfosMap {
		oldFileInfos = append(oldFileInfos, v)
	}
	err = c.restoreFromOldBy(oldFileInfos, false)
	if err != nil {
		return err
	}
	log.Ctx(ctx).Infof("restore file info from not archived success: %s", path)
	// don't delete file,
	return nil
}
func (c *Client) deleteOldVersionFile() error {
	path := filepath.Join(c.DataDir(), "file_infos.json")
	err := os.Remove(path)
	if err != nil {
		return err
	}
	path = filepath.Join(c.DataDir(), "file_infos_archived.json")
	err = os.Remove(path)
	if err != nil {
		return err
	}
	path = filepath.Join(c.DataDir(), "daily_chart_data.json")
	err = os.Remove(path)
	if err != nil {
		return err
	}
	return nil
}

func (c *Client) restoreFromDailyChartDataFile() error {
	path := filepath.Join(c.DataDir(), "daily_chart_data.json")
	log.Ctx(ctx).Infof("restore from daily chart data file: %s", path)
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	var data map[string]map[string]map[string]map[string]struct{}
	err = json.Unmarshal(b, &data)
	if err != nil {
		return err
	}
	err = c.restoreFromDailyChartData(data)
	if err != nil {
		return err
	}
	// delete file
	err = os.Remove(path)
	if err != nil {
		return err
	}
	log.Ctx(ctx).Infof("restore from daily chart data file success: %s", path)
	// don't delete file,
	return nil
}

func (c *Client) restoreFromOldBy(fileInfosMap []oldFileInfo, archived bool) error {
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

// data: map[<date>]map[<level>]map[<word>]map[<word>]struct{}
func (c *Client) restoreFromDailyChartData(data map[string]map[string]map[string]map[string]struct{}) error {
	// 从旧版本恢复数据
	// 1. 从旧版本的数据目录中读取数据
	// 2. 将数据写入到新版本的数据目录中
	// 3. 删除旧版本的数据目录
	// 4. 重启服务

	for date, levelWordMap := range data {
		//	 2024-01-25
		createDay, err := time.ParseInLocation("2006-01-02", date, time.Local)
		if err != nil {
			log.Ctx(ctx).Error(err)
			continue
		}
		createDayInt, _ := strconv.ParseInt(createDay.Format("20060102"), 10, 64)

		for level, wordMap := range levelWordMap {
			var mos []model.KnownWords
			levelInt, _ := strconv.Atoi(level)
			if levelInt == 0 {
				continue
			}
			for word, _ := range wordMap {
				//CreateBatch
				mos = append(mos, model.KnownWords{
					ID:        0,
					Word:      word,
					CreateDay: createDayInt,
					Level:     mtype.WordKnownLevel(levelInt),
					CreateAt:  createDay.UnixMilli(),
					UpdateAt:  time.Now().UnixMilli(),
				})

			}
			err := c.allDao.KnownWordsDao.CreateBatch(ctx, mos...)
			if err != nil {
				log.Ctx(ctx).Error(err)

			}

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
