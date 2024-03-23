import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';
import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/widgets/word_list.dart';
import '../common/global_event.dart';

import '../util/navigator.dart';

class ToadyKnownWords extends StatefulWidget {
  const ToadyKnownWords({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<ToadyKnownWords> {
  int showLevel = prefs.showWordLevel;

  Map<int, List<String>> levelWordsMap = {};

  StreamSubscription<GlobalEvent>? globalEventSubscription;

  void setLevelWordsMap() async {
    final value = await handler.todayKnownWordMap();
    levelWordsMap = value.data ?? {};
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    setLevelWordsMap();
    globalEventSubscription = subscriptGlobalEvent(globalEventHandler);
  }

  int get totalCount {
    return count1 + count2 + count3;
  }

  Map<String, int> get levelWordsLengthMap {
    return {
      '1': (levelWordsMap[1] ?? []).length,
      '2': (levelWordsMap[2] ?? []).length,
      '3': (levelWordsMap[3] ?? []).length,
    };
  } //level: count

  void globalEventHandler(GlobalEvent event) {
    if (event.eventType == GlobalEventType.updateKnownWord) {
      setLevelWordsMap();
      setState(() {});
    }
  }

  List<Widget> actions() {
    return [
      IconButton(
          onPressed: () {
            pushTo(context, const StatisticChart());
          },
          icon: const Icon(Icons.stacked_line_chart))
    ];
  }

  @override
  void dispose() {
    super.dispose();
    globalEventSubscription?.cancel();
  }

  int get count1 => levelWordsLengthMap['1'] ?? 0;

  int get count2 => levelWordsLengthMap['2'] ?? 0;

  int get count3 => levelWordsLengthMap['3'] ?? 0;

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: actions(),
      title: const Text("今日学习单词"),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "词汇分级 (0:陌生, 1级:认识, 2级: 了解, 3级: 熟悉)\n总数量:$totalCount, 1级: $count1  2级: $count2  3级: $count3",
        ),
        const Divider(),
        Expanded(
            child: WordList(
                showLevel: showLevel,
                getLevelWordsMap: handler.todayKnownWordMap))
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: body,
      ),
    );
  }
}
