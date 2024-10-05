package model

import "mywords/model/mtype"

// Don't use the fields that will be updated by gorm hook, such as UpdateAt, CreateAt, DeletedAt.
// Because you don't know when gorm's hook will be executed.
//
// For example,
// UpdateAt field int64, if you don't set gorm tag "autoUpdateTime:milli", it will be updated by seconds
// So, all fields related to CreateAt, UpdateAt, DeletedAt should be set to CreateAt, UpdateAt, DeleteAt.
// Set time explicitly in the program logic, rather than relying on gorm's hook.
// Avoid conflicts with gorm's hook fields, so don't use gorm's hook fields, use your own fields instead

type FileInfo struct {
	ID        int64  `json:"id"`
	Title     string `json:"title"`
	SourceUrl string `json:"sourceUrl"`
	Host      string `json:"host"`
	//FileName  string `json:"fileName"` // 移除字段，请使用filePath
	FilePath string `json:"filePath"` // FIXME 新增字段
	Size     int    `json:"size"`     // bytes
	// LastModified
	TotalCount int   `json:"totalCount"` //
	NetCount   int   `json:"netCount"`   // can be zero
	Archived   bool  `json:"archived"`   // 是否已经归档
	CreateAt   int64 `json:"createAt"`
	// UpdateAt gorm:"autoUpdateTime:milli"
	UpdateAt int64 `json:"updateAt" gorm:"autoUpdateTime:milli"`
}

// KnownWords 已知的单词
type KnownWords struct {
	ID        int64                `json:"id"`
	Word      string               `json:"word"`
	CreateDay int64                `json:"createDay"` //20060102
	Level     mtype.WordKnownLevel `json:"level"`     // 0, 1,2,3 default 0
	CreateAt  int64                `json:"createAt"`
	UpdateAt  int64                `json:"updateAt"`
}

// DictInfo 单词字典信息
// name ,path, createAt, updateAt, size
type DictInfo struct {
	ID       int64  `json:"id"`
	Name     string `json:"name"`
	Path     string `json:"path"`
	CreateAt int64  `json:"createAt"`
	UpdateAt int64  `json:"updateAt"`
	Size     int64  `json:"size"`
}

type KeyValue struct {
	ID    int64       `json:"id"`
	KeyId mtype.KeyId `json:"keyId"` // unique
	// rename Key to KeyId
	Value    string `json:"value"`
	CreateAt int64  `json:"createAt"`
	UpdateAt int64  `json:"updateAt"`
}
