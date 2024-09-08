package mtype

import "fmt"

type WordKnownLevel int // from 1 to 3, 3 stands for the most known. zero means unknown.
var AllWordLevels = [...]WordKnownLevel{1, 2, 3}

func (w WordKnownLevel) Name() string {

	return fmt.Sprintf("%d级", w)
}
