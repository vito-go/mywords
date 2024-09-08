package db

import (
	"fmt"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"mywords/pkg/db/dblogger"
)

var DataNotFound = gorm.ErrRecordNotFound

func NewDB(dbPath string) (*gorm.DB, error) {
	//auto_vacuum 支持的值有：NONE, FULL, INCREMENTAL
	//https://www.sqlite.org/pragma.html#pragma_auto_vacuum
	dsn := fmt.Sprintf("%s", dbPath)
	GDB, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{
		Logger:          dblogger.NewDBLog(dsn),
		CreateBatchSize: 500,
	})
	if err != nil {
		return nil, err
	}
	db, err := GDB.DB()
	if err != nil {
		return nil, err
	}
	db.SetMaxIdleConns(1)
	db.SetMaxOpenConns(1)
	err = db.Ping()
	if err != nil {
		return nil, err
	}
	return GDB, nil
}
