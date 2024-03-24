import 'package:flutter/material.dart';
import 'package:mywords/widgets/word_list.dart';

import 'package:mywords/common/global_event.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';

class WordHeaderRow extends StatefulWidget {
  final String word;

  const WordHeaderRow({super.key, required this.word});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<WordHeaderRow> {
  late final word = widget.word;

  Map<String, int>? wordLevelMap;

  Widget buildWordHeaderRow() {
    if (wordLevelMap == null) {
      return const Row(children: [Text("")]);
    }
    final le = wordLevelMap![word] ?? 0;
    List<Widget> children = [
      Expanded(
          child: Text(word, maxLines: 2, style: const TextStyle(fontSize: 20))),
    ];
    if (!word.contains("_") && !word.contains(" ") && !word.contains(",")) {
      children.addAll([
        buildInkWell(word, 0, le, _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 1, le, _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 2, le, _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 3, le, _updateKnownWords),
      ]);
    }
    return Row(children: children);
  }

  void _updateKnownWords(int level, String word) async {
    final respData = await handler.updateKnownWords(level, word);
    if (respData.code != 0) {
      return;
    }
    wordLevelMap![word] = level;
    setState(() {});
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateKnownWord));
  }

  void _updateWordLevelMap() async {
    wordLevelMap = await handler.queryWordsLevel([word]);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _updateWordLevelMap();
  }

  @override
  Widget build(BuildContext context) {
    return buildWordHeaderRow();
  }
}
