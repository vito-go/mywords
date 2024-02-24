import 'package:flutter/material.dart';
import 'package:mywords/widgets/word_list.dart';

import '../common/global_event.dart';
import '../libso/funcs.dart';

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

  Widget buildWordHeaderRow() {
    List<Widget> children = [
      Expanded(
          child: Text(word, maxLines: 2, style: const TextStyle(fontSize: 20))),
    ];
    if (!word.contains("_") && !word.contains(" ") && !word.contains(",")) {
      children.addAll([
        buildInkWell(word, 0, queryWordLevel(word), _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 1, queryWordLevel(word), _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 2, queryWordLevel(word), _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 3, queryWordLevel(word), _updateKnownWords),
      ]);
    }
    return Row(children: children);
  }

  void _updateKnownWords(int level, String word) {
    final respData = updateKnownWords(level, word);
    if (respData.code != 0) {
      return;
    }
    setState(() {});
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateKnownWord));
  }

  @override
  Widget build(BuildContext context) {
    return buildWordHeaderRow();
  }
}
