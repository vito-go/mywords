package client

import (
	"math"
	"mywords/model/mtype"
	"strconv"
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

func (c *Client) GetToadyChartDateLevelCountMap() map[mtype.WordKnownLevel]int {
	today := time.Now().Format("20060102")
	createDay, _ := strconv.ParseInt(today, 10, 64)
	// copy s.chartDateLevelCountMap
	todayLevelCountMap := make(map[mtype.WordKnownLevel]int, 3)
	items, err := c.allDao.KnownWordsDao.AllItemsByCreateDay(ctx, createDay)
	if err != nil {
		return todayLevelCountMap
	}
	for _, item := range items {
		if item.Level == 0 {
			continue
		}
		todayLevelCountMap[item.Level]++
	}

	return todayLevelCountMap
}

// chartDateLevelCountMap map[string]map[WordKnownLevel]map[string]struct{} // date: {1: {"words":{}}, 2: 200, 3: 300}

func (c *Client) chartDateLevelCountMap() map[string]map[mtype.WordKnownLevel]map[string]struct{} {
	allItems, err := c.allDao.KnownWordsDao.AllItems(ctx)
	if err != nil {
		return nil
	}
	var result = make(map[string]map[mtype.WordKnownLevel]map[string]struct{})
	for _, item := range allItems {
		createDay := strconv.FormatInt(item.CreateDay, 10)
		if _, ok := result[createDay]; !ok {
			result[createDay] = make(map[mtype.WordKnownLevel]map[string]struct{})
		}
		if _, ok := result[createDay][item.Level]; !ok {
			result[createDay][item.Level] = make(map[string]struct{})
		}
		result[createDay][item.Level][item.Word] = struct{}{}
	}
	return result
}
func (c *Client) GetChartData() (*ChartData, error) {

	var chartData = &ChartData{
		//Title:       "每日单词掌握情况分级统计",
		SubTitle:    "",
		XName:       "date",
		YName:       "count",
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

	allCreateDates, err := c.allDao.KnownWordsDao.AllCreateDate(ctx)
	if err != nil {
		return nil, err
	}
	var allDates = make([]string, 0, len(allCreateDates))
	for _, createDay := range allCreateDates {
		allDates = append(allDates, strconv.FormatInt(createDay, 10))
	}
	chartDateLevelCountMap := c.chartDateLevelCountMap()
	for dateIdx, date := range allDates {
		chartData.XTitleMap[dateIdx] = date
		levelCountMap, _ := chartDateLevelCountMap[date]

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
func (c *Client) GetChartDataAccumulate() (*ChartData, error) {

	var chartData = &ChartData{
		//Title:       "累计单词掌握情况统计",
		SubTitle: "",
		XName:    "date",
		//YName:       "累计数量",
		DotDataShow: true,
		XTitleMap:   make(map[int]string),
		LineValues:  make([]lineValue, 0),
		BaselineY:   0,
		MinY:        0,
	}
	//const allTitle = "累计"
	const allTitle = "Accumulative Count"
	chartData.LineValues = []lineValue{
		{Tip: allTitle, BarWidth: 2.0},
	}
	allCreateDates, err := c.allDao.KnownWordsDao.AllCreateDate(ctx)
	if err != nil {
		return nil, err
	}
	var allDates = make([]string, 0, len(allCreateDates))
	for _, createDay := range allCreateDates {
		allDates = append(allDates, strconv.FormatInt(createDay, 10))
	}
	var accumulation = 0
	chartDateLevelCountMap := c.chartDateLevelCountMap()

	for dateIdx, date := range allDates {
		chartData.XTitleMap[dateIdx] = date
		levelCountMap, _ := chartDateLevelCountMap[date]
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
