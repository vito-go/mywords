package client

import (
	"context"
	"errors"
	"fmt"
	"gorm.io/gorm"
	"mywords/model"
	"net"
	"os"
	"sync/atomic"
)

var debug = atomic.Bool{}

func SetDebug(b bool) {
	debug.Store(b)
}

type CodeContent struct {
	Code    int64
	Content any
}

// VacuumDB reorganizes the database file to use disk space more efficiently.
// VACUUM is a SQLite command that reorganizes the database file to use disk space more efficiently.
// It can remove free pages from the database file, reducing the size of the database file.
func (c *Client) VacuumDB(ctx context.Context) (int64, error) {
	tx := c.gdb.WithContext(ctx).Exec("VACUUM")
	if tx.Error != nil {
		return 0, tx.Error
	}
	return tx.RowsAffected, nil
}

var ErrMessageChanFull = errors.New("message chan full")
var ErrMessageChanClosed = errors.New("message chan closed")
var ErrMessageChanTimeout = errors.New("message chan timeout")

const (
	DirDB = "db"
)

// HTTPAddr returns the pprof listen address
func (c *Client) HTTPAddr() string {
	if c.pprofListen == nil {
		return ""
	}
	port := c.pprofListen.Addr().(*net.TCPAddr).Port
	return fmt.Sprintf("http://127.0.0.1:%d/debug/pprof/", port)
}

func (c *Client) Close() error {
	if c.closed.Swap(true) {
		return nil
	}
	d, err := c.gdb.DB()
	if err != nil {
		return err
	}

	if c.pprofListen != nil {
		_ = c.pprofListen.Close()
	}
	return d.Close()
}
func (c *Client) GDB() *gorm.DB {
	return c.gdb
}

// DBSize returns the size of the database file
func (c *Client) DBSize() (int64, error) {
	info, err := os.Stat(c.dbPath)
	if err != nil {
		return 0, err
	}
	return info.Size(), nil
}
func (c *Client) InitCreateTables() error {
	if err := c.gdb.Exec(model.SQL).Error; err != nil {
		return err
	}
	return nil
}
