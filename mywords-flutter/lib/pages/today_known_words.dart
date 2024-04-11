import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/widgets/word_list.dart';

import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/navigator.dart';

class ToadyKnownWords extends StatefulWidget {
  const ToadyKnownWords({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<ToadyKnownWords> {
  int showLevel = prefs.showWordLevel;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: actions(),
      title: const Text("今日学习单词"),
    );

    final body = WordList(
        showLevel: showLevel, getLevelWordsMap: handler.todayKnownWordMap);

    return getScaffold(
      context,
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: body,
      ),
    );
  }
}
