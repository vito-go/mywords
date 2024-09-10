
CREATE TABLE IF NOT EXISTS file_info (
    "id"            INTEGER PRIMARY KEY AUTOINCREMENT,
    "source_url"    TEXT,
    "title"        TEXT,
    "file_name"     TEXT,
    "size"         INTEGER,
    "last_modified" INTEGER,
    "isDir"        INTEGER,
--     Archived     bool  `json:"archived"`     // 是否已经归档
    "archived"      BOOLEAN,
    "total_count"   INTEGER,
    "net_count"     INTEGER,
    "created_at"   INTEGER,
    "update_at"    INTEGER
);
-- sourceUrl is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_sourceUrl ON file_info ("sourceUrl");



-- // KnownWords 已知的单词
-- type KnownWords struct {
-- 	ID        int64  `json:"id"`
-- 	Word      string `json:"word"`
-- 	CreateDay int64  `json:"createDay"` //20060102
-- 	Level     int    `json:"level"`     // 0, 1,2,3 default 0
-- 	CreateAt  int64  `json:"createAt"`
-- 	UpdateAt  int64  `json:"updateAt"`
-- }
CREATE TABLE IF NOT EXISTS known_words (
    "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
    "word"      TEXT,
    "create_day" INTEGER,
    "level"     INTEGER DEFAULT 0,
    "created_at" INTEGER,
    "update_at"  INTEGER
);
-- word is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_word ON known_words ("word");
-- index create_day and update_at
CREATE INDEX IF NOT EXISTS idx_create_day ON known_words ("create_day");
CREATE INDEX IF NOT EXISTS idx_update_at ON known_words ("update_at");



-- type KeyValue struct {
-- 	ID    int64 `json:"id"`
-- 	KeyId KeyId `json:"keyId"`// unique
-- 	// rename Key to KeyId
-- 	Value string `json:"value"`
-- 	CreateAt int64 `json:"createAt"`
-- 	UpdateAt int64 `json:"updateAt"`
-- }
-- type KeyId int
CREATE TABLE IF NOT EXISTS key_value (
    "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
    "key_id"    INTEGER,
    "value"     TEXT,
    "created_at" INTEGER,
    "update_at" INTEGER
);
-- key_id is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_key_id ON key_value ("key_id");