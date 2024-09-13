package dao

import (
	"context"
	"encoding/json"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"mywords/model"
	"mywords/model/mtype"
	"mywords/pkg/db"
	"time"
)

type keyValueDao struct {
	Gdb *gorm.DB
}

func (m *keyValueDao) Table() string {
	return "key_value"
}

//在SQL中，"INSERT OR IGNORE" 通常用于SQLite数据库中，用于在插入数据时如果存在重复记录则忽略；
//而 "INSERT IGNORE" 则通常用于MySQL数据库中，也是用于在插入数据时如果存在重复记录则忽略。两者的作用类似，但语法略有不同，取决于所用的数据库系统。
//在 PostgreSQL 中，使用的语法是 "INSERT INTO … ON CONFLICT DO NOTHING"。这个语法可以在插入数据时如果存在重复记录则忽略。
//
//不同的数据库管理系统采用不同的语法和功能实现方式，这部分是由于各个系统的设计和历史原因。
//虽然这可能会导致在不同数据库系统之间切换时出现一些挑战，但这也是数据库领域的一个普遍现象。通常，这种差异是由于不同的数据库系统在实现 SQL 标准时添加了各自的扩展和优化。

func (m *keyValueDao) Create(ctx context.Context, msg *model.KeyValue) (int64, error) {
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(msg).Error
	if err != nil {
		return 0, err
	}
	return msg.ID, nil
}

// Update .
func (m *keyValueDao) Update(ctx context.Context, msg *model.KeyValue) error {
	// https://gorm.io/zh_CN/docs/update.html#%E6%9B%B4%E6%96%B0%E9%80%89%E5%AE%9A%E5%AD%97%E6%AE%B5
	// 如果您想要在更新时选择、忽略某些字段，您可以使用 Select、Omit
	// If you want to select, update some fields, you can use Select, Omit
	return m.Gdb.WithContext(ctx).Table(m.Table()).Select("*").Omit("id").Where("id = ?", msg.ID).Updates(msg).Error
}

// UpdateOrCreateByKeyId .
func (m *keyValueDao) UpdateOrCreateByKeyId(ctx context.Context, keyId mtype.KeyId, value string) (err error) {
	TX := m.Gdb.WithContext(ctx).Begin()
	defer func() {
		if err != nil {
			TX.Rollback()
			return
		}
		err = TX.Commit().Error
	}()
	// https://gorm.io/zh_CN/docs/update.html#%E6%9B%B4%E6%96%B0%E9%80%89%E5%AE%9A%E5%AD%97%E6%AE%B5
	// 如果您想要在更新时选择、忽略某些字段，您可以使用 Select、Omit
	// If you want to select, update some fields, you can use Select, Omit
	now := time.Now().UnixMilli()
	var updates = map[string]interface{}{"value": value,
		"update_at": now,
	}
	tx := TX.Table(m.Table()).Where("key_id = ?", keyId).Updates(updates)
	if tx.Error != nil {
		return tx.Error
	}
	if tx.RowsAffected == 0 {
		err = TX.Table(m.Table()).Create(&model.KeyValue{
			ID:       0,
			KeyId:    keyId,
			Value:    value,
			CreateAt: now,
			UpdateAt: now,
		}).Error
		if err != nil {
			return err
		}
	}
	return nil

}

// CreateBatch .
func (m *keyValueDao) CreateBatch(ctx context.Context, msgs ...model.KeyValue) error {
	if len(msgs) == 0 {
		return nil
	}
	return m.Gdb.WithContext(ctx).Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(msgs).Error
}

func (m *keyValueDao) AllItems(ctx context.Context) ([]model.KeyValue, error) {
	var msgs []model.KeyValue
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Order("update_at DESC").Find(&msgs).Error
	return msgs, err
}
func (m *keyValueDao) Proxy(ctx context.Context) (string, error) {
	item, err := m.ItemByKeyId(ctx, mtype.KeyIdProxy)
	if err != nil {
		return "", err
	}
	return item.Value, nil
}
func (m *keyValueDao) QueryShareInfo(ctx context.Context) (*mtype.ShareInfo, error) {
	item, err := m.ItemByKeyId(ctx, mtype.KeyIdShareInfo)
	if err != nil {
		return nil, err
	}
	var shareInfo mtype.ShareInfo
	err = json.Unmarshal([]byte(item.Value), &shareInfo)
	if err != nil {
		return nil, err
	}
	return &shareInfo, nil
}

// SetShareInfo .If not exist, create it.
func (m *keyValueDao) SetShareInfo(ctx context.Context, shareInfo *mtype.ShareInfo) error {
	value, err := json.Marshal(shareInfo)
	if err != nil {
		return err
	}
	return m.UpdateOrCreateByKeyId(ctx, mtype.KeyIdShareInfo, string(value))
}

// SetProxyURL .
func (m *keyValueDao) SetProxyURL(ctx context.Context, proxyURL string) error {
	return m.UpdateOrCreateByKeyId(ctx, mtype.KeyIdProxy, proxyURL)
}

func (m *keyValueDao) ItemByKeyId(ctx context.Context, keyId int64) (*model.KeyValue, error) {
	var msg model.KeyValue
	tx := m.Gdb.WithContext(ctx).Table(m.Table()).Find(&msg)
	if tx.Error != nil {
		return nil, tx.Error
	}
	if tx.RowsAffected == 0 {
		return nil, db.DataNotFound
	}
	return &msg, nil
}

// DeleteById .
func (m *keyValueDao) DeleteById(ctx context.Context, id int64) error {
	return m.Gdb.WithContext(ctx).Table(m.Table()).Where("id = ?", id).Delete(&model.KeyValue{}).Error
}
