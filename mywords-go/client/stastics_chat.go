package client

import (
	"math"
	"mywords/model/mtype"
	"sort"
	"time"
)

type lineValue struct {
	Tip      string  `json:"tip"`
	BarWidth float64 `json:"barWidth"`
	FlSpots  [][]int `json:"flSpots"` // x,y
}
type ChartData struct {
	Title       string         `json:"title"`
	SubTitle    string         `json:"subTitle"`
	XName       string         `json:"xName"`
	YName       string         `json:"yName"`
	DotDataShow bool           `json:"dotDataShow"`
	XTitleMap   map[int]string `json:"xTitleMap"`  // 0: "2020-01-01", 1: "2020-01-02", ...
	LineValues  []lineValue    `json:"lineValues"` // multiple lines
	BaselineY   int            `json:"baselineY"`
	MinY        int            `json:"minY"`
	MaxY        int            `json:"maxY,omitempty"`
}

func (chartData *ChartData) SetMinY() {
	var minY = math.MaxInt
	for _, lv := range chartData.LineValues {
		for _, v := range lv.FlSpots {
			if v[1] < minY {
				minY = v[1]
			}
		}
	}
	if minY != math.MaxInt {
		chartData.MinY = minY
	}
}
func (chartData *ChartData) SetMaxY() {
	var maxY = -math.MaxInt
	for _, lv := range chartData.LineValues {
		for _, v := range lv.FlSpots {
			if v[1] > maxY {
				maxY = v[1]
			}
		}
	}
	if maxY != -math.MaxInt {
		chartData.MaxY = maxY
	}
}

const lastDays = 20

func (s *Client) GetToadyChartDateLevelCountMap() map[mtype.WordKnownLevel]int {
	today := time.Now().Format("2006-01-02")
	// copy s.chartDateLevelCountMap

	if s.chartDateLevelCountMap.Len() == 0 {
		return nil
	}
	todayLevelCountMap := make(map[mtype.WordKnownLevel]int, 3)
	levelWordMap, _ := s.chartDateLevelCountMap.GetMapByKey(today)
	for _, level := range mtype.AllWordLevels {
		todayLevelCountMap[level] = len(levelWordMap[level])
	}
	return todayLevelCountMap
}
func (s *Client) GetChartData() (*ChartData, error) {

	var chartData = &ChartData{
		Title:       "每日单词掌握情况分级统计",
		SubTitle:    "",
		XName:       "日期",
		YName:       "单词数量",
		DotDataShow: true,
		XTitleMap:   make(map[int]string),
		LineValues:  make([]lineValue, 0),
		BaselineY:   0,
		MinY:        0,
	}
	const allTitle = "all"
	chartData.LineValues = []lineValue{
		{Tip: allTitle, BarWidth: 2.0},
		{Tip: mtype.WordKnownLevel(1).Name(), BarWidth: 0.5},
		{Tip: mtype.WordKnownLevel(2).Name(), BarWidth: 0.75},
		{Tip: mtype.WordKnownLevel(3).Name(), BarWidth: 1.0},
	}
	allDates := s.chartDateLevelCountMap.AllKeys()
	sort.Strings(allDates)
	for dateIdx, date := range allDates {
		chartData.XTitleMap[dateIdx] = date
		levelCountMap, _ := s.chartDateLevelCountMap.GetMapByKey(date)

		for i := 0; i < len(chartData.LineValues); i++ {
			if chartData.LineValues[i].Tip == allTitle {
				var allCount int
				for _, m := range levelCountMap {
					allCount += len(m)
				}
				chartData.LineValues[i].FlSpots = append(chartData.LineValues[i].FlSpots, []int{dateIdx, allCount})
				break
			}
		}
		for _, level := range mtype.AllWordLevels {
			count := len(levelCountMap[level])
			for i := 0; i < len(chartData.LineValues); i++ {
				if chartData.LineValues[i].Tip == level.Name() {
					chartData.LineValues[i].FlSpots = append(chartData.LineValues[i].FlSpots, []int{dateIdx, count})
					break
				}
			}
		}
	}
	// at most chartData.LineValues[i].FlSpots has 14 elements, last 14 days
	for i := 0; i < len(chartData.LineValues); i++ {
		if len(chartData.LineValues[i].FlSpots) > lastDays {
			chartData.LineValues[i].FlSpots = chartData.LineValues[i].FlSpots[len(chartData.LineValues[i].FlSpots)-lastDays:]
		}
	}
	chartData.SetMinY()
	chartData.SetMaxY()
	return chartData, nil
}
func (s *Client) GetChartDataAccumulate() (*ChartData, error) {

	var chartData = &ChartData{
		Title:       "累计单词掌握情况统计",
		SubTitle:    "",
		XName:       "日期",
		YName:       "累计数量",
		DotDataShow: true,
		XTitleMap:   make(map[int]string),
		LineValues:  make([]lineValue, 0),
		BaselineY:   0,
		MinY:        0,
	}
	const allTitle = "累计"
	chartData.LineValues = []lineValue{
		{Tip: allTitle, BarWidth: 2.0},
	}
	allDates := s.chartDateLevelCountMap.AllKeys()
	sort.Strings(allDates)
	var accumulation = 0
	for dateIdx, date := range allDates {
		chartData.XTitleMap[dateIdx] = date
		levelCountMap, _ := s.chartDateLevelCountMap.GetMapByKey(date)
		for i := 0; i < len(chartData.LineValues); i++ {
			if chartData.LineValues[i].Tip == allTitle {
				var allCount int
				for _, m := range levelCountMap {
					allCount += len(m)
				}
				accumulation += allCount
				chartData.LineValues[i].FlSpots = append(chartData.LineValues[i].FlSpots, []int{dateIdx, accumulation})
				break
			}
		}
	}
	// at most chartData.LineValues[i].FlSpots has 14 elements, last 14 days
	for i := 0; i < len(chartData.LineValues); i++ {
		if len(chartData.LineValues[i].FlSpots) > lastDays {
			chartData.LineValues[i].FlSpots = chartData.LineValues[i].FlSpots[len(chartData.LineValues[i].FlSpots)-lastDays:]
		}
	}
	chartData.SetMinY()
	chartData.SetMaxY()
	return chartData, nil
}

func (s *Client) updateKnownWordCountLineChart(level mtype.WordKnownLevel, word string) {
	l, ok := s.queryWordLevel(word)
	if ok && level <= l {
		// only update level to higher
		return
	}
	today := time.Now().Format("2006-01-02")
	for _, wordLevel := range mtype.AllWordLevels {
		levelWordMap, ok := s.chartDateLevelCountMap.GetMapByKey(today)
		if ok {
			wordMap := levelWordMap[wordLevel]
			wordMapNew := make(map[string]struct{})
			for w := range wordMap {
				wordMapNew[w] = struct{}{}
			}
			delete(wordMapNew, word)
			s.chartDateLevelCountMap.Set(today, wordLevel, wordMapNew)
			continue
		}
	}
	levelWordMap, ok := s.chartDateLevelCountMap.GetMapByKey(today)
	if !ok {
		levelWordMap = make(map[mtype.WordKnownLevel]map[string]struct{})
	}
	wordMap, _ := levelWordMap[level]
	wordMapNew := make(map[string]struct{})
	for w := range wordMap {
		wordMapNew[w] = struct{}{}
	}

	wordMapNew[word] = struct{}{}
	s.chartDateLevelCountMap.Set(today, level, wordMapNew)

	return
}
