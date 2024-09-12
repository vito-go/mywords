package main

import "C"
import "context"

//export VacuumDB
func VacuumDB() *C.char {
	rowAffects, err := serverGlobal.VacuumDB(context.Background())
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(rowAffects)
}

//export DBSize
func DBSize() *C.char {
	size, err := serverGlobal.DBSize()
	if err != nil {
		return CharErr(err.Error())
	}
	return CharOk(size)
}
