import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';

import 'package:mywords/widgets/word_common.dart';

import 'package:mywords/common/queue.dart';
import 'package:mywords/libso/resp_data.dart';

class _WordLevel {
  String word;
  int level;

  _WordLevel(this.word, this.level);
}

class WordList extends StatefulWidget {
  const WordList(
      {super.key, required this.showLevel, required this.getLevelWordsMap});

  final int showLevel;

  final FutureOr<RespData<Map<int, List<String>>>> Function()
      getLevelWordsMap; // level: [word1,word2]

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<WordList> {
  late final FutureOr<RespData<Map<int, List<String>>>> Function()
      getLevelWordsMap = widget.getLevelWordsMap; // level: [word1,word2]

  Map<int, List<String>> levelWordsMap = {}; // level: [word1,word2]
  late int showLevel = widget.showLevel;

  void globalEventHandler(Event event) {
    if (event.eventType == EventType.updateKnownWord) {
      if (event.param is Map) {
        if (event.param["word"] != null && event.param["level"] != null) {
          final word = event.param["word"].toString();
          final level = event.param["level"] as int;
          levelWordsMap[1]?.remove(word);
          levelWordsMap[2]?.remove(word);
          levelWordsMap[3]?.remove(word);
          // no need to add when 0
          levelWordsMap[level]?.add(word);
          setState(() {});
        }
      }
    }
  }

  int get count1 => (levelWordsMap[1] ?? []).length;

  int get count2 => (levelWordsMap[2] ?? []).length;

  int get count3 => (levelWordsMap[3] ?? []).length;
  StreamSubscription<Event>? globalEventSubscription;

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
  void initState() {
    super.initState();
    globalEventSubscription = consume(globalEventHandler);
    _updateLevelWordsMap();
  }

  void _updateLevelWordsMap() async {
    final value = await getLevelWordsMap();
    levelWordsMap = value.data ?? {};
    setState(() {});
  }

  Widget buildWordLevelRow(int idx, String word, int realLevel) {
    List<Widget> children = [
      Text("[${idx + 1}]"),
      TextButton(
          onPressed: () {
            showWord(context, word);
          },
          child: Text(word, maxLines: 2, style: const TextStyle(fontSize: 18))),
      const Expanded(child: Text('')),
      buildInkWell(context, word, 0, realLevel),
      const SizedBox(width: 6),
      buildInkWell(context, word, 1, realLevel),
      const SizedBox(width: 6),
      buildInkWell(context, word, 2, realLevel),
      const SizedBox(width: 6),
      buildInkWell(context, word, 3, realLevel),
      const SizedBox(width: 10),
    ];
    return Row(children: children);
  }

  Widget get listViewBuild {
    final List<_WordLevel> items = [];
    switch (showLevel) {
      case 0:
        final l1 = levelWordsMap[1] ?? [];
        items.addAll(List<_WordLevel>.generate(
            l1.length, (index) => _WordLevel(l1[index], 1)));
        final l2 = levelWordsMap[2] ?? [];
        items.addAll(List<_WordLevel>.generate(
            l2.length, (index) => _WordLevel(l2[index], 2)));
        final l3 = levelWordsMap[3] ?? [];
        items.addAll(List<_WordLevel>.generate(
            l3.length, (index) => _WordLevel(l3[index], 3)));
        break;
      case 1:
        final l1 = levelWordsMap[1] ?? [];
        items.addAll(List<_WordLevel>.generate(
            l1.length, (index) => _WordLevel(l1[index], 1)));
        break;
      case 2:
        final l2 = levelWordsMap[2] ?? [];
        items.addAll(List<_WordLevel>.generate(
            l2.length, (index) => _WordLevel(l2[index], 2)));
        break;
      case 3:
        final l3 = levelWordsMap[3] ?? [];
        items.addAll(List<_WordLevel>.generate(
            l3.length, (index) => _WordLevel(l3[index], 3)));
        break;
    }
    return ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        return buildWordLevelRow(index, items[index].word, items[index].level);
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      itemCount: items.length,
    );
  }

  @override
  void dispose() {
    super.dispose();
    globalEventSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        wordLevelRichText(),
        const Divider(),
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text("分级筛选"),
              buildShowLevel(0, label: "all", onTap: () {
                showLevel = 0;
                prefs.showWordLevel = 0;
                setState(() {});
              }, showLevel: showLevel),
              buildShowLevel(1, label: "1", showLevel: showLevel, onTap: () {
                showLevel = 1;
                prefs.showWordLevel = 1;
                setState(() {});
              }),
              buildShowLevel(2, label: "2", showLevel: showLevel, onTap: () {
                showLevel = 2;
                prefs.showWordLevel = 2;
                setState(() {});
              }),
              buildShowLevel(3, label: "3", showLevel: showLevel, onTap: () {
                showLevel = 3;
                prefs.showWordLevel = 3;
                setState(() {});
              }),
            ],
          ),
        ),
        Expanded(child: listViewBuild),
      ],
    );
  }
}

Widget buildShowLevel(int level,
    {required int showLevel,
    required String label,
    required GestureTapCallback onTap}) {
  if (showLevel == level) {
    return InkWell(
        onTap: null,
        child: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text(label),
        ));
  }
  return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: null,
        child: Text(label),
      ));
}
