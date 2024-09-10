package dao

import (
	"context"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"mywords/model"
	"mywords/pkg/db"
)

type fileInfoDao struct {
	Gdb *gorm.DB
}

func (m *fileInfoDao) Table() string {
	return "file_info"
}

//在SQL中，"INSERT OR IGNORE" 通常用于SQLite数据库中，用于在插入数据时如果存在重复记录则忽略；
//而 "INSERT IGNORE" 则通常用于MySQL数据库中，也是用于在插入数据时如果存在重复记录则忽略。两者的作用类似，但语法略有不同，取决于所用的数据库系统。
//在 PostgreSQL 中，使用的语法是 "INSERT INTO … ON CONFLICT DO NOTHING"。这个语法可以在插入数据时如果存在重复记录则忽略。
//
//不同的数据库管理系统采用不同的语法和功能实现方式，这部分是由于各个系统的设计和历史原因。
//虽然这可能会导致在不同数据库系统之间切换时出现一些挑战，但这也是数据库领域的一个普遍现象。通常，这种差异是由于不同的数据库系统在实现 SQL 标准时添加了各自的扩展和优化。

func (m *fileInfoDao) Create(ctx context.Context, msg *model.FileInfo) (int64, error) {
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(msg).Error
	if err != nil {
		return 0, err
	}
	return msg.ID, nil
}

// Update .
func (m *fileInfoDao) Update(ctx context.Context, msg *model.FileInfo) error {
	// https://gorm.io/zh_CN/docs/update.html#%E6%9B%B4%E6%96%B0%E9%80%89%E5%AE%9A%E5%AD%97%E6%AE%B5
	// 如果您想要在更新时选择、忽略某些字段，您可以使用 Select、Omit
	// If you want to select, update some fields, you can use Select, Omit
	return m.Gdb.WithContext(ctx).Table(m.Table()).Select("*").Omit("id").Where("id = ?", msg.ID).Updates(msg).Error
}

// CreateBatch .
func (m *fileInfoDao) CreateBatch(ctx context.Context, msgs ...model.FileInfo) error {
	if len(msgs) == 0 {
		return nil
	}
	return m.Gdb.WithContext(ctx).Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(msgs).Error
}

func (m *fileInfoDao) AllItemsByArchived(ctx context.Context, archived bool) ([]model.FileInfo, error) {
	var items []model.FileInfo
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Where("archived = ?", archived).Order("updated_at DESC").Find(&items).Error
	return items, err
}

// AllFileNames .
func (m *fileInfoDao) AllFileNames(ctx context.Context) ([]string, error) {
	var result []string
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Select("file_name").Find(&result).Error
	return result, err
}
func (m *fileInfoDao) ItemByID(ctx context.Context, id int64) (*model.FileInfo, error) {
	var result model.FileInfo
	tx := m.Gdb.WithContext(ctx).Table(m.Table()).Where("id = ?", id).Find(&result)
	err := tx.Error
	if err != nil {
		return nil, err
	}
	if tx.RowsAffected == 0 {
		return nil, db.DataNotFound
	}
	return &result, err
}
func (m *fileInfoDao) ItemBySourceUrl(ctx context.Context, sourceUrl string) (*model.FileInfo, error) {
	var result model.FileInfo
	tx := m.Gdb.WithContext(ctx).Table(m.Table()).Where("source_url = ?", sourceUrl).Find(&result)
	err := tx.Error
	if err != nil {
		return nil, err
	}
	if tx.RowsAffected == 0 {
		return nil, db.DataNotFound
	}
	return &result, err
}

// DeleteById .
func (m *fileInfoDao) DeleteById(ctx context.Context, id int64) (int64, error) {
	tx := m.Gdb.WithContext(ctx).Table(m.Table()).Where("id = ?", id).Delete(&model.FileInfo{})
	return tx.RowsAffected, tx.Error
}
