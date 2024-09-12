import 'package:flutter/material.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/util.dart';

import 'package:mywords/widgets/line_chart.dart';

import '../common/global_event.dart';

class StatisticChart extends StatefulWidget {
  const StatisticChart({super.key});

  @override
  State createState() {
    return _State();
  }
}

class _State extends State<StatisticChart> with SingleTickerProviderStateMixin {
  List<Widget> get myTabs => [
        const Tab(
          text: "每日统计",
          icon: Icon(Icons.today),
        ),
        const Tab(
          text: "累计统计",
          icon: Icon(Icons.view_day),
        ),
      ];

  ChartLineData? todayData;
  ChartLineData? accumulateData;
  Map<String, dynamic> todayCountMap = {};

  Future<void> updateTodayCountMap() async {
    final respData = await handler.getToadyChartDateLevelCountMap();
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    todayCountMap = respData.data!;
  }

  void initData() async {
    todayData = (await handler.getChartData()).data!;
    accumulateData = (await handler.getChartDataAccumulate()).data!;
    await updateTodayCountMap();
    setState(() {});
  }

  List<Widget> get tableWidgets {
    if (todayData == null || accumulateData == null) {
      return [
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
      ];
    }
    return [
      LineChartSample(chartLineData: todayData!, isCurved: true),
      LineChartSample(chartLineData: accumulateData!, isCurved: false),
    ];
  }

  Widget get toolTipToday {
    final count1 = todayCountMap['1'] ?? 0;
    final count2 = todayCountMap['2'] ?? 0;
    final count3 = todayCountMap['3'] ?? 0;
    final total = count1 + count2 + count3;
    return Tooltip(
      message: "今日学习单词数量: $total\n1级:$count1 2级:$count2 3级:$count3",
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 30),
      child: const Icon(Icons.info),
    );
  }

  Widget get toolTipAccumulate {
    return const Tooltip(
      showDuration: Duration(seconds: 30),
      message: "请注意：每日学习的单词可能与往日学习的存在重复，因此您累计学习的数量可能与已知单词总数不一致。",
      triggerMode: TooltipTriggerMode.tap,
      child: Icon(Icons.help),
    );
  }

  @override
  void initState() {
    super.initState();
    initData();
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateLineChart));
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text("学习统计"),
      bottom: TabBar(
        tabs: myTabs,
        labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(),
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        Padding(padding: const EdgeInsets.only(right: 16), child: toolTipToday),
        Padding(
            padding: const EdgeInsets.only(right: 20), child: toolTipAccumulate)
      ],
    );
    return DefaultTabController(
      length: myTabs.length,
      child: getScaffold(
        context,
        appBar: appBar,
        body: TabBarView(children: tableWidgets),
      ),
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
