package dict

import (
	"sort"
	"strings"
)

func SearchByKeyWord(keyWord string, dictMap map[string]string) []string {
	const atMost = 100
	var result = make([]string, 1, 100)
	_, exist := dictMap[keyWord]
	lowerKeyWord := strings.ToLower(keyWord)
	for word := range dictMap {
		lowerWord := strings.ToLower(word)
		if len(result) >= atMost {
			break
		}
		if lowerWord == lowerKeyWord {
			continue
		}
		if strings.HasPrefix(lowerWord, lowerKeyWord) {
			result = append(result, word)
		}
	}
	sort.Slice(result[1:], func(i, j int) bool {
		return result[1:][i] < result[1:][j]
	})

	if exist {
		result[0] = keyWord
	} else {
		result = result[1:]
	}
	return result
}
