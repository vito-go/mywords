package dao

import "gorm.io/gorm"

type AllDao struct {
	FileInfoDao   *fileInfoDao
	KeyValueDao   *keyValueDao
	DictInfoDao   *dictInfoDao
	KnownWordsDao *knownWordsDao
}

func NewAllDao(gdb *gorm.DB) *AllDao {
	return &AllDao{
		FileInfoDao:   &fileInfoDao{Gdb: gdb},
		KeyValueDao:   &keyValueDao{Gdb: gdb},
		DictInfoDao:   &dictInfoDao{Gdb: gdb},
		KnownWordsDao: &knownWordsDao{Gdb: gdb},
	}

}
