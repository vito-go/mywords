package dblogger

import (
	"context"
	"mywords/pkg/log"
	"time"

	"gorm.io/gorm/logger"
)

const slowThreshold = 200 * time.Millisecond

type DBLog struct {
	dsn string // 哨兵监控使用的数据库dsn
}

func NewDBLog(dsn string) *DBLog {
	return &DBLog{dsn: dsn}
}

func (d *DBLog) LogMode(level logger.LogLevel) logger.Interface {
	return d
}

func (d *DBLog) Info(ctx context.Context, s string, i ...interface{}) {

}

func (d *DBLog) Warn(ctx context.Context, s string, i ...interface{}) {

}

func (d *DBLog) Error(ctx context.Context, s string, i ...interface{}) {

}

// Trace sql慢查询. 哨兵监控
func (d *DBLog) Trace(ctx context.Context, begin time.Time, fc func() (sql string, rowsAffected int64), err error) {
	sqls, rowsAffected := fc()
	_, _ = sqls, rowsAffected
	defer func() {
		log.Ctx(ctx).Infof("rowsAffected: %d, timeElapsed: %s, sqls: %s", rowsAffected, time.Since(begin), sqls)
	}()
	elapsed := time.Since(begin)
	if elapsed > slowThreshold {
		log.Ctx(ctx).Warnf("Slow SQL: rowsAffected: %d, timeElapsed: %s, sqls: %s", rowsAffected, time.Since(begin), sqls)
		return
	}
}
