package db

import (
	"testing"
)

func TestNewDB(t *testing.T) {
	gdb, err := NewDB("test.db")
	if err != nil {
		panic(err)
	}
	if err != nil {
		t.Fatal(err)
	}

	TX := gdb.Exec("CREATE TABLE IF NOT EXISTS `proxy` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `ip` TEXT, `port` INTEGER, `protocol` TEXT, `country` TEXT, `anonymity` TEXT, `source` TEXT, `speed` REAL, `created_at` DATETIME, `updated_at ` DATETIME);")
	if TX.Error != nil {
		t.Fatal(TX.Error)
	}
	var result []map[string]interface{}
	for i := 0; i < 1000000; i++ {
		result = append(result, map[string]interface{}{
			"ip":        "3434",
			"port":      111,
			"protocol":  "11",
			"country":   "23",
			"anonymity": "43",
		})

	}
	err = gdb.Table("proxy").Create(result).Error
	if err != nil {
		t.Fatal(err)
	}
	// Update
	err = gdb.Table("proxy").Where("id > ?", 1).Updates(map[string]interface{}{
		"ip": "111",
	}).Error
	if err != nil {
		t.Fatal(err)
	}
	// vacuum
	TX = gdb.Exec("VACUUM")
	if TX.Error != nil {
		t.Fatal(TX.Error)
	}
	t.Logf("rows affected: %d", TX.RowsAffected)

}
