package model

type FileInfo struct {
	ID        int64  `json:"id"`
	Title     string `json:"title"`
	SourceUrl string `json:"sourceUrl"`
	FileName  string `json:"fileName"`
	Size      int64  `json:"size"` // bytes
	// LastModified
	// Deprecated: use UpdateAt
	LastModified int64 `json:"lastModified"` // milliseconds
	IsDir        bool  `json:"isDir"`        // always false
	TotalCount   int   `json:"totalCount"`   //
	NetCount     int   `json:"netCount"`     // can be zero
	Archived     bool  `json:"archived"`     // 是否已经归档
	CreateAt     int64 `json:"createAt"`
	UpdateAt     int64 `json:"updateAt"`
}

// KnownWords 已知的单词
type KnownWords struct {
	ID        int64  `json:"id"`
	Word      string `json:"word"`
	CreateDay int64  `json:"createDay"` //20060102
	Level     int    `json:"level"`     // 0, 1,2,3 default 0
	CreateAt  int64  `json:"createAt"`
	UpdateAt  int64  `json:"updateAt"`
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
	ID    int64 `json:"id"`
	KeyId KeyId `json:"keyId"` // unique
	// rename Key to KeyId
	Value    string `json:"value"`
	CreateAt int64  `json:"createAt"`
	UpdateAt int64  `json:"updateAt"`
}
type KeyId int
