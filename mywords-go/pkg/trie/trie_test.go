package trie

import (
	"fmt"
	"mywords/dict"
	"mywords/pkg/log"
	"slices"
	"testing"
	"time"
)

func TestTrie(t *testing.T) {
	// Create a new Trie and insert words
	trie := NewTrie()
	const dispatch = 256 // if there are so many words, we can dispatch them to different directories
	words := []string{"apple", "applet", "applaud", "banana", "band", "freedom", "democracy", "republic", "demos", "demolish", "demote", "demobilize"}
	for i, word := range words {
		// 文件名是单词的编码
		trie.Insert(word, fmt.Sprintf("%d/%d.html", i%dispatch, i))
	}
	// Search for words with the prefix "appl"
	prefix := "demo"
	results := trie.SearchPrefix(prefix, 100)

	if len(results) == 0 {
		t.Fatal("No words found with the prefix", prefix)
	}
	if len(results) != 5 {
		t.Fatal("Expected 3 words, got", len(results))
	}
	// Output: Results for prefix demo : [demobilize demote demolish demos democracy]
	t.Log("Results for prefix", prefix, ":", results)
	word := "democracy"
	value, ok := trie.FindWord(word)
	if !ok {
		t.Fatal("Word not found", word)
	}
	t.Log("Results for word ", word, ":", value)
	word = "dictator"
	value, ok = trie.FindWord(word)
	if ok {
		t.Fatal("Word found", word)
	}
}

func TestSearch(t *testing.T) {
	result1 := trie.SearchPrefix("freedom", 100)
	t.Logf("SearchPrefix Results for prefix freedom : %v", result1)
	result2 := dict.SearchByKeyWord("freedom", dict.DefaultDictWordMap)
	t.Logf("DefaultDictWordMap Results for prefix freedom : %v", result2)
	if !slices.Equal(result1, result2) {
		t.Fatal("Results are not equal")
	}
}

// TestFindWord
func TestFindWord(t *testing.T) {
	words := []string{"apple", "boy", "cat", "dog", "dictator", "elephant", "freedom", "democracy", "zebra"}
	for _, word := range words {
		value1, ok1 := trie.FindWord(word)
		value2, ok2 := dict.DefaultDictWordMap[word]
		if value1 != value2 || ok1 != ok2 {
			t.Fatal("Results are not equal")
		}
	}
}

var trie *Trie

func init() {
	trie = NewTrie()
	st := time.Now()
	for word, define := range dict.DefaultDictWordMap {
		trie.Insert(word, define)
	}
	log.Println("Insert time:", time.Since(st))

}

func BenchmarkSearch(b *testing.B) {
	kws := []string{"app", "bo", "cat", "dog", "ele", "freedom", "democracy", "zeb"}
	//for i := 0; i < b.N; i++ {
	//	trie.SearchPrefix("app", 100)
	//}
	for _, kw := range kws {
		name := fmt.Sprintf("SearchPrefix(%s)", kw)
		b.Run(name+"-ByStack", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				trie.SearchPrefix(kw, 100)
			}
		})
		b.Run(name+"-DFS", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				trie.SearchPrefixByDFS(kw)
			}
		})
		b.Run(name+"-DefaultDictWordMap", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				dict.SearchByKeyWord(kw, dict.DefaultDictWordMap)
			}
		})
	}

}

func BenchmarkFindWord(b *testing.B) {
	words := []string{"freedom", "democracy"}
	for _, word := range words {
		name := fmt.Sprintf("FindWord(%s)", word)
		b.Run(name, func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				trie.FindWord(word)
			}
		})
		b.Run(name+"-DefaultDictWordMap", func(b *testing.B) {
			_, _ = dict.DefaultDictWordMap[word]
		})
	}

}
