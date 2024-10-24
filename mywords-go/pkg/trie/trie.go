package trie

import (
	"strings"
	"sync"
)

// Node represents a node in the Trie
type Node struct {
	children map[rune]*Node
	//isEnd    bool
	value *string
}

// Trie represents the Trie structure
type Trie struct {
	mux  sync.RWMutex //TODO Is it necessary to add a mutex?. We should not insert and search at the same time.
	root *Node
}

// NewTrie creates a new Trie
func NewTrie() *Trie {
	return &Trie{root: &Node{children: make(map[rune]*Node)}, mux: sync.RWMutex{}}
}

// Insert inserts a word into the Trie
func (t *Trie) Insert(word string, value string) {
	t.mux.Lock()
	defer t.mux.Unlock()
	node := t.root
	for _, char := range word {
		if _, exists := node.children[char]; !exists {
			node.children[char] = &Node{children: make(map[rune]*Node)}
		}
		node = node.children[char]
	}
	node.value = &value
}

// SearchPrefixCaseSensitive finds all words with the given prefix and case-sensitive
// Apple can not match 'apple' but can match 'apple pie'. Because the first letter is capitalized.
func (t *Trie) SearchPrefixCaseSensitive(prefix string, count int64, caseSensitive bool) []string {
	node := t.root
	var exists bool
	prefixNew := make([]rune, 0, len(prefix))
	for _, char := range prefix {
		if _, exists = node.children[char]; !exists {
			if !caseSensitive {
				return nil
			}
			char = []rune(strings.ToLower(string(char)))[0]
			if _, exists = node.children[char]; !exists {
				char = []rune(strings.ToUpper(string(char)))[0]
				if _, exists = node.children[char]; !exists {
					return nil // Prefix not found
				}
			}
			//return nil // Prefix not found
		}
		prefixNew = append(prefixNew, char)
		node = node.children[char]
	}
	prefix = string(prefixNew)
	return t.findWordsByStack(node, prefix, count)
}
func (t *Trie) SearchPrefix(prefix string, count int64) []string {
	node := t.root
	for _, char := range prefix {
		if _, exists := node.children[char]; !exists {
			return nil // Prefix not found
		}
		node = node.children[char]
	}
	return t.findWordsByStack(node, prefix, count)
}

// SearchPrefixByDFS finds all words with the given prefix by DFS
func (t *Trie) SearchPrefixByDFS(prefix string) []string {
	node := t.root
	for _, char := range prefix {
		if _, exists := node.children[char]; !exists {
			return nil // Prefix not found
		}
		node = node.children[char]
	}
	return t.findWordsByDFS(node, prefix)
}

// FindWord finds a word in the Trie
// 算法时间复杂度为O(n)
func (t *Trie) FindWord(word string) (string, bool) {
	t.mux.RLock()
	defer t.mux.RUnlock()
	node := t.root
	for _, char := range word {
		if _, exists := node.children[char]; !exists {
			return "", false // Word not found
		}
		node = node.children[char]
	}
	if node.value != nil {
		return *node.value, true
	}
	return "", false
}

type stackItem struct {
	current *Node
	prefix  string
}

func (t *Trie) findWordsByStack(node *Node, prefix string, count int64) []string {
	t.mux.RLock()
	defer t.mux.RUnlock()
	var results []string
	stack := []stackItem{{current: node, prefix: prefix}} // 初始化栈，包含根节点和当前前缀
	for len(stack) > 0 {
		if len(results) >= int(count) {
			return results
		}
		// 从栈中弹出一个元素
		item := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		// 检查当前节点
		if item.current.value != nil {
			results = append(results, item.prefix)
		}
		// 将子节点和对应前缀推入栈
		for char, child := range item.current.children {
			stack = append(stack, stackItem{current: child, prefix: item.prefix + string(char)})
		}
	}
	return results
}

// findWords performs a DFS to find all words under the given node
func (t *Trie) findWordsByDFS(node *Node, prefix string) []string {
	t.mux.RLock()
	defer t.mux.RUnlock()
	var results []string
	if node.value != nil {
		results = append(results, prefix)
	}
	for char, child := range node.children {
		results = append(results, t.findWordsByDFS(child, prefix+string(char))...)
	}
	return results
}
