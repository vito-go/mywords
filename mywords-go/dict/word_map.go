package dict

import (
	"bytes"
	"compress/gzip"
	_ "embed"
	"encoding/gob"
)

var DefaultDictWordMap map[string]string

//go:embed gob-gz/default_dict.gob.gz
var dictGobGz []byte

func init() {
	initDictMap()
	initDictLinkMap()
}
func initDictMap() {
	r, err := gzip.NewReader(bytes.NewReader(dictGobGz))
	if err != nil {
		panic(err)
	}
	defer func() {
		if err = r.Close(); err != nil {
			panic(err)
		}
	}()
	err = gob.NewDecoder(r).Decode(&DefaultDictWordMap)
	if err != nil {
		panic(err)
	}
}

// WordLinkMap 存储一些复数、过去时等单词的原本单词指向.例如 dictators: dictator,democratized: democratize
var WordLinkMap map[string]string

//go:embed gob-gz/word_link.gob.gz
var dictLinkGobGz []byte

func initDictLinkMap() {
	r, err := gzip.NewReader(bytes.NewReader(dictLinkGobGz))
	if err != nil {
		panic(err)
	}
	defer func() {
		if err = r.Close(); err != nil {
			panic(err)
		}
	}()
	err = gob.NewDecoder(r).Decode(&WordLinkMap)
	if err != nil {
		panic(err)
	}
}
