
CREATE TABLE IF NOT EXISTS file_info (
    "id"            INTEGER PRIMARY KEY AUTOINCREMENT,
    "source_url"    TEXT,
    "title"        TEXT,
    "file_name"     TEXT,
    "size"         INTEGER,
    "last_modified" INTEGER,
    "is_dir"        INTEGER,
     "archived"      BOOLEAN,
    "total_count"   INTEGER,
    "net_count"     INTEGER,
    "created_at"   INTEGER,
    "updated_at"    INTEGER
);
-- sourceUrl is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_sourceUrl ON file_info ("sourceUrl");



-- // KnownWords 已知的单词
-- type KnownWords struct {
-- 	ID        int64  `json:"id"`
-- 	Word      string `json:"word"`
-- 	CreateDay int64  `json:"createDay"` //20060102
-- 	Level     int    `json:"level"`     // 0, 1,2,3 default 0
-- 	CreatedAt  int64  `json:"createdAt"`
-- 	UpdatedAt  int64  `json:"updatedAt"`
-- }
CREATE TABLE IF NOT EXISTS known_words (
    "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
    "word"      TEXT,
    "create_day" INTEGER,
    "level"     INTEGER DEFAULT 0,
    "created_at" INTEGER,
    "updated_at"  INTEGER
);
-- word is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_word ON known_words ("word");
-- index create_day and update_at
CREATE INDEX IF NOT EXISTS idx_create_day ON known_words ("create_day");
CREATE INDEX IF NOT EXISTS idx_update_at ON known_words ("update_at");



-- type KeyId int
CREATE TABLE IF NOT EXISTS key_value (
    "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
    "key_id"    INTEGER,
    "value"     TEXT,
    "created_at" INTEGER,
    "updated_at" INTEGER
);
-- key_id is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_key_id ON key_value ("key_id");

CREATE TABLE IF NOT EXISTS dict_info (
    "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
    "name"      TEXT,
    "path"      TEXT, -- UNIQUE
    "size"      INTEGER,
    "created_at" INTEGER,
    "updated_at" INTEGER
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_path ON dict_info ("path");