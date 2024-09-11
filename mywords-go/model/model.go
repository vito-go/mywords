package model

import "mywords/model/mtype"

type FileInfo struct {
	ID        int64  `json:"id"`
	Title     string `json:"title"`
	SourceUrl string `json:"sourceUrl"`
	Host      string `json:"host"`
	FileName  string `json:"fileName"`
	Size      int64  `json:"size"` // bytes
	// LastModified
	// Deprecated: use UpdatedAt
	LastModified int64 `json:"lastModified"` // milliseconds
	IsDir        bool  `json:"isDir"`        // always false
	TotalCount   int   `json:"totalCount"`   //
	NetCount     int   `json:"netCount"`     // can be zero
	Archived     bool  `json:"archived"`     // 是否已经归档
	CreatedAt    int64 `json:"createdAt"`
	UpdatedAt    int64 `json:"updatedAt"`
}

// KnownWords 已知的单词
type KnownWords struct {
	ID        int64                `json:"id"`
	Word      string               `json:"word"`
	CreateDay int64                `json:"createDay"` //20060102
	Level     mtype.WordKnownLevel `json:"level"`     // 0, 1,2,3 default 0
	CreatedAt int64                `json:"createdAt"`
	UpdatedAt int64                `json:"updatedAt"`
}

// DictInfo 单词字典信息
// name ,path, createAt, updatedAt, size
type DictInfo struct {
	ID        int64  `json:"id"`
	Name      string `json:"name"`
	Path      string `json:"path"`
	CreatedAt int64  `json:"createdAt"`
	UpdatedAt int64  `json:"updatedAt"`
	Size      int64  `json:"size"`
}

type KeyValue struct {
	ID    int64       `json:"id"`
	KeyId mtype.KeyId `json:"keyId"` // unique
	// rename Key to KeyId
	Value     string `json:"value"`
	CreatedAt int64  `json:"createdAt"`
	UpdatedAt int64  `json:"updatedAt"`
}
