package server

type FileInfo struct {
	Title        string `json:"title"`
	SourceUrl    string `json:"sourceUrl"`
	FileName     string `json:"fileName"`
	Size         int64  `json:"size"`         // bytes
	LastModified int64  `json:"lastModified"` // milliseconds
	IsDir        bool   `json:"isDir"`        // always false
	TotalCount   int    `json:"totalCount"`
	NetCount     int    `json:"netCount"`
}
