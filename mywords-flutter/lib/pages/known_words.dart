import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';

import 'package:mywords/widgets/word_list.dart';
import 'package:mywords/common/global_event.dart';
import 'package:mywords/util/get_scaffold.dart';

class KnownWords extends StatefulWidget {
  const KnownWords({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<KnownWords> {
  int showLevel = prefs.showWordLevel;

  Map<int, List<String>> levelWordsMap = {};
  StreamSubscription<GlobalEvent>? globalEventSubscription;

  void setAllKnownWordMap() async {
    final value = await handler.allKnownWordMap();
    levelWordsMap = value.data ?? {};
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    setAllKnownWordMap();
    globalEventSubscription = subscriptGlobalEvent(globalEventHandler);
  }

  int get totalCount {
    return count1 + count2 + count3;
  }

  int get count1 => levelWordsLengthMap['1'] ?? 0;

  int get count2 => levelWordsLengthMap['2'] ?? 0;

  int get count3 => levelWordsLengthMap['3'] ?? 0;

  Map<String, int> get levelWordsLengthMap {
    return {
      '1': (levelWordsMap[1] ?? []).length,
      '2': (levelWordsMap[2] ?? []).length,
      '3': (levelWordsMap[3] ?? []).length,
    };
  } //level: count

  void globalEventHandler(GlobalEvent event) {
    if (event.eventType == GlobalEventType.updateKnownWord) {
      setState(() {});
    }
  }

  List<Widget> actions() {
    return [];
  }

  @override
  void dispose() {
    super.dispose();
    globalEventSubscription?.cancel();
  }
  Widget wordLevelRichText() {
    return RichText(
      text: TextSpan(
          style: const TextStyle(color: Colors.black),
          text: "",
          children: [
            const TextSpan(
                text: "词汇分级 (0:陌生, 1级:认识, 2:了解, 3:熟悉)\n",
                style: TextStyle(color: Colors.blueGrey)),
            const TextSpan(text: "1级: "),
            TextSpan(
                text: "$count1",
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.normal)),
            const TextSpan(text: "  2级: "),
            TextSpan(
                text: "$count2",
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.normal)),
            const TextSpan(text: "  3级: "),
            TextSpan(
                text: "$count3",
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.normal)),
          ]),
    );
  }
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: actions(),
      title: const Text("我的单词库"),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        wordLevelRichText(),
        const Divider(),
        Expanded(
            child: WordList(
                showLevel: showLevel,
                getLevelWordsMap: handler.allKnownWordMap))
      ],
    );

    return getScaffold(context,
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: body,
      ),
    );
  }
}
