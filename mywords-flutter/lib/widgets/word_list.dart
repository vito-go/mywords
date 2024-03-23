import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';
import 'package:mywords/widgets/word_common.dart';

import '../common/global_event.dart';
import '../libso/resp_data.dart';
import '../util/util.dart';

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

  @override
  void initState() {
    super.initState();
    _updateLevelWordsMap();
  }

  _updateKnownWordsSetState(int level, String word) async {
    final respData = await handler.updateKnownWords(level, word);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    levelWordsMap[1]?.remove(word);
    levelWordsMap[2]?.remove(word);
    levelWordsMap[3]?.remove(word);
    levelWordsMap[level]?.add(word);
    myPrint(levelWordsMap);
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateKnownWord));
    setState(() {});
  }

  void _updateLevelWordsMap() async {
    final value = await getLevelWordsMap();
    levelWordsMap = value.data ?? {};
    myPrint(levelWordsMap.length);
    setState(() {});
  }

  Widget buildWordLevelRow(int idx, String word, int realLevel) {
    List<Widget> children = [
      Text("[${idx + 1}]"),
      TextButton(
          onPressed: () {
            showWord(context, word);
          },
          child: Text(
            word,
            maxLines: 2,
            style: const TextStyle(fontSize: 16),
          )),
      const Expanded(child: Text('')),
      buildInkWell(word, 0, realLevel, _updateKnownWordsSetState),
      const SizedBox(width: 6),
      buildInkWell(word, 1, realLevel, _updateKnownWordsSetState),
      const SizedBox(width: 6),
      buildInkWell(word, 2, realLevel, _updateKnownWordsSetState),
      const SizedBox(width: 6),
      buildInkWell(word, 3, realLevel, _updateKnownWordsSetState),
      const SizedBox(width: 16),
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
          return buildWordLevelRow(
              index, items[index].word, items[index].level);
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemCount: items.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

InkWell buildInkWell(String word, int showLevel, int realLevel,
    void Function(int level, String word) onTap) {
  if (showLevel == realLevel) {
    return InkWell(
      child: SizedBox(
          height: 32,
          width: 32,
          child: CircleAvatar(
            backgroundColor: Colors.orange,
            child: Text(showLevel.toString()),
          )),
    );
  }
  return InkWell(
      child: SizedBox(
          height: 32,
          width: 32,
          child: CircleAvatar(
            backgroundColor: null,
            child: Text(showLevel.toString()),
          )),
      onTap: () {
        onTap(showLevel, word);
      });
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
