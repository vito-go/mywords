//go:build flutter

package main

import (
	"fmt"
)

func main() {
	// 编译为so库供flutter使用
	// must Init when using the exported method in this package
	fmt.Println("Hello World from Flutter")
}
