package dao

import "gorm.io/gorm"

type AllDao struct {
	gdb           *gorm.DB
	FileInfoDao   *fileInfoDao
	KeyValueDao   *keyValueDao
	DictInfoDao   *dictInfoDao
	KnownWordsDao *knownWordsDao
}

func NewAllDao(gdb *gorm.DB) *AllDao {
	return &AllDao{
		gdb:           gdb,
		FileInfoDao:   &fileInfoDao{Gdb: gdb},
		KeyValueDao:   &keyValueDao{Gdb: gdb},
		DictInfoDao:   &dictInfoDao{Gdb: gdb},
		KnownWordsDao: &knownWordsDao{Gdb: gdb},
	}
}

// GDB returns the gorm.DB instance
func (a *AllDao) GDB() *gorm.DB {
	return a.gdb
}
