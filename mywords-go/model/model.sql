
CREATE TABLE IF NOT EXISTS file_info (
    "id"            INTEGER PRIMARY KEY AUTOINCREMENT,
    "source_url"    TEXT,
    "title"        TEXT,
    "file_name"     TEXT,
    "size"         INTEGER DEFAULT 0,
    "last_modified" INTEGER DEFAULT 0,
    "is_dir"        INTEGER DEFAULT 0,
     "archived"      BOOLEAN,
    "total_count"   INTEGER DEFAULT 0,
    "net_count"     INTEGER  DEFAULT 0,
    "created_at"   INTEGER ,
    "updated_at"    INTEGER
);
-- sourceUrl is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_sourceUrl ON file_info ("sourceUrl");






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



CREATE TABLE IF NOT EXISTS known_words (
                                           "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
                                           "word"      TEXT,
                                           "create_day" INTEGER,
                                           "level"     INTEGER DEFAULT 0,
                                           "updated_at"  INTEGER,
                                           "created_at" INTEGER
);
-- word is unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_word ON known_words ("word");
CREATE INDEX IF NOT EXISTS idx_create_day ON known_words ("create_day");
CREATE INDEX IF NOT EXISTS idx_updated_at ON known_words ("updated_at ");
