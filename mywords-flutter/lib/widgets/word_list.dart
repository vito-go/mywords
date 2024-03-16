import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/widgets/word_common.dart';

import '../common/global_event.dart';
import '../libso/funcs.dart';
import '../util/util.dart';

class WordList extends StatefulWidget {
  const WordList(
      {super.key, required this.showLevel, required this.levelWordsMap});

  final int showLevel;
  final Map<int, List<String>> levelWordsMap; // level: [word1,word2]

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<WordList> {
  late Map<int, List<String>> levelWordsMap =
      widget.levelWordsMap; // level: [word1,word2]
  late int showLevel = widget.showLevel;

  @override
  void initState() {
    super.initState();
  }

  _updateKnownWordsSetState(int level, String word) {
    _updateKnownWords(context, level, word);
    setState(() {});
  }

  Widget get listViewWord {
    List<Widget> items = [];
    List<String> allWords = [];
    allWords.addAll(levelWordsMap[1] ?? []);
    allWords.addAll(levelWordsMap[2] ?? []);
    allWords.addAll(levelWordsMap[3] ?? []);

    for (int i = 0; i < allWords.length; i++) {
      final word = allWords[i];
      final int realLevel = queryWordLevel(word);
      if (showLevel != 0 && showLevel != realLevel) {
        continue;
      }
      List<Widget> children = [
        Text("[${i + 1}]"),
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
      items.add(Row(children: children));
    }

    return ListView.separated(
        itemBuilder: (BuildContext context, int index) => items[index],
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
        Expanded(child: listViewWord),
      ],
    );
  }
}

Widget contextMenuBuilder(
    BuildContext context, EditableTextState editableTextState) {
  final textEditingValue = editableTextState.textEditingValue;
  final TextSelection selection = textEditingValue.selection;
  final buttonItems = editableTextState.contextMenuButtonItems;
  if (!selection.isCollapsed) {
    final selectText = selection.textInside(textEditingValue.text).trim();
    if (!selectText.contains(" ")) {
      buttonItems.add(ContextMenuButtonItem(
          onPressed: () {
            showWord(context, selectText);
          },
          label: "Lookup"));
    }
  }
  return AdaptiveTextSelectionToolbar.buttonItems(
    buttonItems: buttonItems,
    anchors: editableTextState.contextMenuAnchors,
  );
}

void _updateKnownWords(BuildContext context, int level, String word) {
  final respData = updateKnownWords(level, word);
  if (respData.code != 0) {
    myToast(context, respData.message);
    return;
  }
  addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateKnownWord));
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
