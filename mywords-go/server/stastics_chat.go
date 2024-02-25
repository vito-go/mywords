package server

import (
	"fmt"
	"sort"
	"time"
)

type lineValue struct {
	Tip     string  `json:"tip"`
	FlSpots [][]int `json:"flSpots"` // x,y
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
}

const lastDays = 20

func (s *Server) GetToadyChartDateLevelCountMap() map[WordKnownLevel]int {
	today := time.Now().Format("2006-01-02")
	// copy s.chartDateLevelCountMap
	s.mux.Lock()
	defer s.mux.Unlock()
	if len(s.chartDateLevelCountMap) == 0 {
		return nil
	}
	todayLevelCountMap := make(map[WordKnownLevel]int, 3)
	for date, levelCountMap := range s.chartDateLevelCountMap {
		if date == today {
			for level, countMap := range levelCountMap {
				todayLevelCountMap[level] = len(countMap)
			}
			break
		}
	}
	return todayLevelCountMap
}
func (s *Server) GetChartData() (*ChartData, error) {
	s.mux.Lock()
	defer s.mux.Unlock()
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
		{Tip: allTitle},
		{Tip: WordKnownLevel(1).Name()},
		{Tip: WordKnownLevel(2).Name()},
		{Tip: WordKnownLevel(3).Name()},
	}
	allDates := make([]string, 0, len(s.chartDateLevelCountMap))
	for date := range s.chartDateLevelCountMap {
		allDates = append(allDates, date)
	}
	sort.Strings(allDates)
	for dateIdx, date := range allDates {
		chartData.XTitleMap[dateIdx] = date
		levelCountMap := s.chartDateLevelCountMap[date]

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

		for level, count := range levelCountMap {
			for i := 0; i < len(chartData.LineValues); i++ {
				if chartData.LineValues[i].Tip == level.Name() {
					chartData.LineValues[i].FlSpots = append(chartData.LineValues[i].FlSpots, []int{dateIdx, len(count)})
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
	return chartData, nil
}
func (s *Server) GetChartDataAccumulate() (*ChartData, error) {
	s.mux.Lock()
	defer s.mux.Unlock()
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
		{Tip: allTitle},
	}
	allDates := make([]string, 0, len(s.chartDateLevelCountMap))
	for date := range s.chartDateLevelCountMap {
		allDates = append(allDates, date)
	}
	sort.Strings(allDates)
	var accumulation = 0
	for dateIdx, date := range allDates {
		chartData.XTitleMap[dateIdx] = date
		levelCountMap := s.chartDateLevelCountMap[date]
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
		fmt.Println(len(chartData.LineValues[i].FlSpots))
		if len(chartData.LineValues[i].FlSpots) > lastDays {
			chartData.LineValues[i].FlSpots = chartData.LineValues[i].FlSpots[len(chartData.LineValues[i].FlSpots)-lastDays:]
		}
	}
	return chartData, nil
}

func (s *Server) updateKnownWordCountLineChart(level WordKnownLevel, word string) {
	l, ok := s.QueryWordLevel(word)
	if ok && level <= l {
		// only update level to higher
		return
	}
	today := time.Now().Format("2006-01-02")
	if len(s.chartDateLevelCountMap) == 0 {
		s.chartDateLevelCountMap = make(map[string]map[WordKnownLevel]map[string]struct{})
	}
	_, ok = s.chartDateLevelCountMap[today]
	if !ok {
		s.chartDateLevelCountMap[today] = make(map[WordKnownLevel]map[string]struct{})
	}
	_, ok = s.chartDateLevelCountMap[today][level]
	if !ok {
		s.chartDateLevelCountMap[today][level] = make(map[string]struct{})
	}
	for knownLevel, wordMap := range s.chartDateLevelCountMap[today] {
		if _, ok = wordMap[word]; ok {
			delete(s.chartDateLevelCountMap[today][knownLevel], word)
			break
		}
	}
	s.chartDateLevelCountMap[today][level][word] = struct{}{}
	return
}
