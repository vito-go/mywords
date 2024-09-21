import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/common/global.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler.dart';

import 'package:mywords/widgets/word_common.dart';

import '../common/queue.dart';

class WordList extends StatefulWidget {
  const WordList({super.key, required this.createDay});

  final int createDay; // 0 all words;  the other day known words

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<WordList> {
  late final createDay = widget.createDay; // 1 all words; 2 today known words
  List<String> allWords = [];
  StreamSubscription<Event>? eventConsumer;

  Map<int, int> get levelWordsMap => Global.levelDistribute(allWords);
  int showLevel = prefs.showWordLevel;

  int get count1 => levelWordsMap[1] ?? 0;

  int get count2 => levelWordsMap[2] ?? 0;

  int get count3 => levelWordsMap[3] ?? 0;

  Widget wordLevelRichText() {
    final normalStyle = Theme.of(context).textTheme.bodyMedium;
    final TextStyle levelStyle = TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.normal);
    return RichText(
      text: TextSpan(
          style: const TextStyle(color: Colors.black),
          text: "",
          children: [
            const TextSpan(
                text: "词汇分级 (0:陌生, 1级:认识, 2:了解, 3:熟悉)\n",
                style: TextStyle(color: Colors.blueGrey)),
            TextSpan(text: "1级: ", style: normalStyle),
            TextSpan(text: "$count1", style: levelStyle),
            TextSpan(text: "  2级: ", style: normalStyle),
            TextSpan(text: "$count2", style: levelStyle),
            TextSpan(text: "  3级: ", style: normalStyle),
            TextSpan(text: "$count3", style: levelStyle),
          ]),
    );
  }

  int order = 1; //  1: id desc, 2: id asc ,3 words desc, 4 words asc

  void updateAllWords() async {
    allWords = await handler.allWordsByCreateDayAndOrder(createDay, order);
    setState(() {});
  }

  void eventHandler(Event event) {
    if (event.eventType == EventType.updateKnownWord) {
      setState(() {});
    }
  }
  @override
  void initState() {
    super.initState();
    updateAllWords();
    eventConsumer = consume(eventHandler);
  }

  Widget buildWordLevelRow(int idx, String word) {
     List<Widget> children = [
      Text("[${idx + 1}]"),
      TextButton(
          onPressed: () {
            showWord(context, word);
          },
          child: Text(word, maxLines: 2, style: const TextStyle(fontSize: 18))),
      const Expanded(child: Text('')),
      buildInkWell(context, word, 0  ),
      const SizedBox(width: 6),
      buildInkWell(context, word, 1 ),
      const SizedBox(width: 6),
      buildInkWell(context, word, 2  ),
      const SizedBox(width: 6),
      buildInkWell(context, word, 3 ),
      const SizedBox(width: 10),
    ];
    return Row(children: children);
  }

  List<String> get showWords {
    final List<String> result = [];
    switch (showLevel) {
      case 0:
        result.addAll(allWords);
        break;
      case 1:
        result.addAll(
            allWords.where((element) => Global.allKnownWordsMap[element] == 1));
        break;
      case 2:
        result.addAll(
            allWords.where((element) => Global.allKnownWordsMap[element] == 2));
        break;
      case 3:
        result.addAll(
            allWords.where((element) => Global.allKnownWordsMap[element] == 3));
        break;
    }
    return result;
  }

  Widget get listViewBuild {
    return ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        final word = showWords[index];
        return buildWordLevelRow(index, word);
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      itemCount: showWords.length,
    );
  }

  @override
  void dispose() {
    super.dispose();
    eventConsumer?.cancel();
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
