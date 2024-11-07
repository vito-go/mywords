package dao

import (
	"context"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"mywords/model"
)

type sources struct {
	Gdb *gorm.DB
}

func (m *sources) Table() string {
	return "sources"
}

//在SQL中，"INSERT OR IGNORE" 通常用于SQLite数据库中，用于在插入数据时如果存在重复记录则忽略；
//而 "INSERT IGNORE" 则通常用于MySQL数据库中，也是用于在插入数据时如果存在重复记录则忽略。两者的作用类似，但语法略有不同，取决于所用的数据库系统。
//在 PostgreSQL 中，使用的语法是 "INSERT INTO … ON CONFLICT DO NOTHING"。这个语法可以在插入数据时如果存在重复记录则忽略。
//
//不同的数据库管理系统采用不同的语法和功能实现方式，这部分是由于各个系统的设计和历史原因。
//虽然这可能会导致在不同数据库系统之间切换时出现一些挑战，但这也是数据库领域的一个普遍现象。通常，这种差异是由于不同的数据库系统在实现 SQL 标准时添加了各自的扩展和优化。

func (m *sources) Create(ctx context.Context, msg *model.Sources) (int64, error) {
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(msg).Error
	if err != nil {
		return 0, err
	}
	return msg.ID, nil
}

// CreateBatch .
func (m *sources) CreateBatch(ctx context.Context, items ...model.Sources) error {
	if len(items) == 0 {
		return nil
	}
	return m.Gdb.WithContext(ctx).Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(items).Error
}

func (m *sources) AllItems(ctx context.Context) ([]model.Sources, error) {
	var msgs []model.Sources
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Find(&msgs).Error
	return msgs, err
}

// DeleteById .
func (m *sources) DeleteById(ctx context.Context, id int64) (int64, error) {
	tx := m.Gdb.WithContext(ctx).Table(m.Table()).Where("id = ?", id).Delete(&model.Sources{})
	if tx.Error != nil {
		return 0, tx.Error
	}
	return tx.RowsAffected, nil
}

// DeleteBySource .
func (m *sources) DeleteBySource(TX *gorm.DB, source string) (int64, error) {
	tx := TX.Table(m.Table()).Where("source = ?", source).Delete(&model.Sources{})
	if tx.Error != nil {
		return 0, tx.Error
	}
	return tx.RowsAffected, nil
}

// ItemById .
func (m *sources) ItemById(ctx context.Context, id int64) (*model.Sources, error) {
	var msg model.Sources
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Where("id = ?", id).First(&msg).Error
	return &msg, err
}
