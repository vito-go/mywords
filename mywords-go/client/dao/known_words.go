package dao

import (
	"context"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"mywords/model"
	"mywords/model/mtype"
	"strconv"
	"time"
)

type knownWordsDao struct {
	Gdb *gorm.DB
}

func (m *knownWordsDao) Table() string {
	return "known_words"
}

//在SQL中，"INSERT OR IGNORE" 通常用于SQLite数据库中，用于在插入数据时如果存在重复记录则忽略；
//而 "INSERT IGNORE" 则通常用于MySQL数据库中，也是用于在插入数据时如果存在重复记录则忽略。两者的作用类似，但语法略有不同，取决于所用的数据库系统。
//在 PostgreSQL 中，使用的语法是 "INSERT INTO … ON CONFLICT DO NOTHING"。这个语法可以在插入数据时如果存在重复记录则忽略。
//
//不同的数据库管理系统采用不同的语法和功能实现方式，这部分是由于各个系统的设计和历史原因。
//虽然这可能会导致在不同数据库系统之间切换时出现一些挑战，但这也是数据库领域的一个普遍现象。通常，这种差异是由于不同的数据库系统在实现 SQL 标准时添加了各自的扩展和优化。

func (m *knownWordsDao) Create(ctx context.Context, msg *model.KnownWords) (int64, error) {
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(msg).Error
	if err != nil {
		return 0, err
	}
	return msg.ID, nil
}

// Update .
func (m *knownWordsDao) Update(ctx context.Context, msg *model.KnownWords) error {
	// https://gorm.io/zh_CN/docs/update.html#%E6%9B%B4%E6%96%B0%E9%80%89%E5%AE%9A%E5%AD%97%E6%AE%B5
	// 如果您想要在更新时选择、忽略某些字段，您可以使用 Select、Omit
	// If you want to select, update some fields, you can use Select, Omit
	return m.Gdb.WithContext(ctx).Table(m.Table()).Select("*").Omit("id").Where("id = ?", msg.ID).Updates(msg).Error
}

// UpdateOrCreate .
func (m *knownWordsDao) UpdateOrCreate(ctx context.Context, word string, level mtype.WordKnownLevel) (err error) {
	if level == 0 {
		// delete
		return m.Gdb.WithContext(ctx).Table(m.Table()).Where("word = ?", word).Delete(&model.KnownWords{}).Error
	}
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
	var updates = map[string]interface{}{
		"update_at": now,
		"level":     level,
	}
	tx := TX.Table(m.Table()).Where("word = ?", word).Updates(updates)
	if tx.Error != nil {
		return tx.Error
	}
	if tx.RowsAffected > 0 {
		return nil
	}
	createDay, _ := strconv.ParseInt(time.Now().Format("20060102"), 10, 64)
	err = TX.Table(m.Table()).Create(&model.KnownWords{
		ID:        0,
		Word:      word,
		CreateDay: createDay,
		Level:     level,
		CreateAt:  now,
		UpdateAt:  now,
	}).Error
	if err != nil {
		return err
	}
	return nil
}

// CreateBatch .
func (m *knownWordsDao) CreateBatch(ctx context.Context, msgs ...model.KnownWords) error {
	if len(msgs) == 0 {
		return nil
	}
	return m.Gdb.WithContext(ctx).Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(msgs).Error
}

func (m *knownWordsDao) AllItems(ctx context.Context) ([]model.KnownWords, error) {
	var msgs []model.KnownWords
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Order("update_at DESC").Find(&msgs).Error
	return msgs, err
}

// DeleteByWordsTX .
func (m *knownWordsDao) DeleteByWordsTX(TX *gorm.DB, words ...string) error {
	return TX.Table(m.Table()).Where("word IN ?", words).Delete(&model.KnownWords{}).Error
}

// CreateBatchTX .
func (m *knownWordsDao) CreateBatchTX(TX *gorm.DB, msgs ...model.KnownWords) error {
	if len(msgs) == 0 {
		return nil
	}
	return TX.Table(m.Table()).Clauses(clause.Insert{
		Modifier: "OR IGNORE",
	}).Create(msgs).Error
}
func (m *knownWordsDao) AllItemsByCreateDay(ctx context.Context, createDay int64) ([]model.KnownWords, error) {
	var msgs []model.KnownWords
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Where("create_day = ?", createDay).Order("update_at DESC").Find(&msgs).Error
	return msgs, err
}

// AllWordsByIdDesc .
func (m *knownWordsDao) AllWordsByIdDesc(ctx context.Context) ([]string, error) {
	var msgs []string
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Order("id DESC").Find(&msgs).Error
	return msgs, err
}

// AllWordsByCreateDayWithIdDesc .
func (m *knownWordsDao) AllWordsByCreateDayWithIdDesc(ctx context.Context, createDay int64) ([]string, error) {
	var msgs []string
	tx := m.Gdb.WithContext(ctx).Table(m.Table()).Select("word")
	if createDay > 0 {
		tx = tx.Where("create_day = ?", createDay)
	}
	err := tx.Order("id DESC").Find(&msgs).Error
	return msgs, err
}

// AllWordsByCreateDayWithIdAsc .
func (m *knownWordsDao) AllWordsByCreateDayWithIdAsc(ctx context.Context, createDay int64) ([]string, error) {
	var msgs []string
	tx := m.Gdb.WithContext(ctx).Table(m.Table()).Select("word")
	if createDay > 0 {
		tx = tx.Where("create_day = ?", createDay)
	}
	err := tx.Order("id ASC").Find(&msgs).Error
	return msgs, err
}

// AllCreateDate . DISTINCT(create_day) ORDER BY create_day DESC
func (m *knownWordsDao) AllCreateDate(ctx context.Context) ([]int64, error) {
	var result []int64
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Select("DISTINCT(create_day)").Order("create_day ASC").Find(&result).Error
	return result, err

}

func (m *knownWordsDao) LevelWordsCountMap(ctx context.Context) (map[mtype.WordKnownLevel]int64, error) {
	// SELECT level, COUNT(*) FROM known_words GROUP BY level;
	type result struct {
		Level mtype.WordKnownLevel
		Count int64
	}
	var items []result
	err := m.Gdb.WithContext(ctx).Table(m.Table()).Select("level, COUNT(*) as count").Group("level").Find(&items).Error
	if err != nil {
		return nil, err
	}
	resultMap := make(map[mtype.WordKnownLevel]int64, len(items))
	for _, item := range items {
		resultMap[item.Level] = item.Count
	}
	return resultMap, nil

}

// DeleteById .
func (m *knownWordsDao) DeleteById(ctx context.Context, id int64) error {
	return m.Gdb.WithContext(ctx).Table(m.Table()).Where("id = ?", id).Delete(&model.KnownWords{}).Error
}
