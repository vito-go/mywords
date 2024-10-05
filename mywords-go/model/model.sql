
CREATE TABLE IF NOT EXISTS file_info (
    "id"            INTEGER PRIMARY KEY AUTOINCREMENT,
    "source_url"    TEXT,
    "host"          TEXT,
    "title"        TEXT,
    "file_path"     TEXT,
    "size"         INTEGER DEFAULT 0,
    "last_modified" INTEGER DEFAULT 0,
    "is_dir"        INTEGER DEFAULT 0,
     "archived"      BOOLEAN,
    "total_count"   INTEGER DEFAULT 0,
    "net_count"     INTEGER  DEFAULT 0,
    "create_at"   INTEGER ,
    "update_at"    INTEGER
);
-- sourceUrl is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_source_url ON file_info ("source_url");
-- host is index
CREATE INDEX IF NOT EXISTS idx_host ON file_info ("host");
-- index update_at
CREATE INDEX IF NOT EXISTS idx_update_at ON file_info ("update_at");



-- type KeyId int
CREATE TABLE IF NOT EXISTS key_value (
    "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
    "key_id"    INTEGER,
    "value"     TEXT,
    "create_at" INTEGER,
    "update_at" INTEGER
);
-- key_id is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_key_id ON key_value ("key_id");

CREATE TABLE IF NOT EXISTS dict_info (
    "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
    "name"      TEXT,
    "path"      TEXT, -- UNIQUE
    "size"      INTEGER,
    "create_at" INTEGER,
    "update_at" INTEGER
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_path ON dict_info ("path");



CREATE TABLE IF NOT EXISTS known_words (
                                           "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
                                           "word"      TEXT,
                                           "create_day" INTEGER,
                                           "level"     INTEGER DEFAULT 0,
                                           "update_at"  INTEGER,
                                           "create_at" INTEGER
);
-- word is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_word ON known_words ("word");
CREATE INDEX IF NOT EXISTS idx_create_day ON known_words ("create_day");
CREATE INDEX IF NOT EXISTS idx_update_at ON known_words ("update_at");
