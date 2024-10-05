import 'package:flutter/material.dart';

import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/util/util.dart';
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
      actions: actions(),
      // title: const Text("今日学习单词"),
      title: const Text("Today's Learning"),
    );
    //  today  format: 20060102
    // final now = DateTime.now();
    // final today =
    //     "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    // final int todayInt = int.parse(today);
    // due to the time difference between the underlying library and flutter, todayInt here is inaccurate, use the time of the underlying library, pass 1 to represent today
    final body = WordList(createDay: 1);
    // myPrint("todayInt: $todayInt");
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
