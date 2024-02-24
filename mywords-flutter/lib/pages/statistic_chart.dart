import 'package:flutter/material.dart';
import 'package:mywords/libso/funcs.dart';
import 'package:mywords/widgets/line_chart.dart';

class StatisticChart extends StatefulWidget {
  const StatisticChart({super.key});

  @override
  State createState() {
    return _State();
  }
}

class WordChart extends StatelessWidget {
  const WordChart({super.key});

  Map<String, dynamic> get todayCountMap {
    final respData = getToadyChartDateLevelCountMap();
    if (respData.code != 0) {
      return {};
    }
    final data = respData.data ?? {};
    return data;
  }

  Widget get toolTipToday {
    final count1 = todayCountMap['1'] ?? 0;
    final count2 = todayCountMap['2'] ?? 0;
    final count3 = todayCountMap['3'] ?? 0;
    final total = count1 + count2 + count3;
    return Tooltip(
      message:
      "今日学习单词数量: $total\n1级:$count1 2级:$count2 3级:$count3",
      triggerMode: TooltipTriggerMode.tap,
      child: const Icon(Icons.info),
    );
  }


  @override
  Widget build(BuildContext context) {
    final body = LineChartSample(chartLineData: getChartData().data!);
    return Scaffold(
      appBar: AppBar(
        title: const Text("每日统计"),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: toolTipToday,
          )
        ],
      ),
      body: body,
    );
  }
}

class _State extends State<StatisticChart> {
  ChartLineData? data;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (data == null) {
      body = const Center(
        child: CircularProgressIndicator(),
      );
    }
    body = LineChartSample(chartLineData: getChartData().data!);
    return Scaffold(
      appBar: AppBar(
        title: const Text("每日统计"),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
      ),
      body: body,
    );
  }
}

final demoChartLineData = ChartLineData.fromJson({
  "title": "每日统计",
  "subTitle": "背单词",
  "xName": "日期",
  "yName": "数量",
  "dotDataShow": true,
  "xTitleMap": {
    "0": "01-24",
    "1": "01-24",
    "2": "01-24",
    "3": "01-24",
    "4": "01-24",
    "5": "01-24",
    "6": "01-24",
    "7": "01-24",
    "8": "01-24",
    "9": "01-24",
    "10": "01-24",
    "11": "01-24",
    "12": "01-24",
    "13": "01-24",
    "14": "01-24",
  },
  "lineValues": [
    {
      "tip": "1级别",
      "flSpots": [
        [0, 0],
        [1, 0],
        [2, 0],
        [3, 0],
        [4, 0],
        [5, 0],
        [6, 65],
        [7, 10],
        [8, 76],
        [9, 40],
        [10, 48],
        [11, 44],
        [12, 76],
        [13, 78],
        [14, 6],
      ]
    }
  ],
  "baselineY": 0,
  // "maxY": 86.97,
  "minY": 0
});