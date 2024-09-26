import 'package:flutter/material.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/widgets/word_common.dart';
import 'package:mywords/libso/handler.dart';

class WordDefaultMeaning extends StatefulWidget {
  const WordDefaultMeaning({
    super.key,
    required this.word,
    required this.meaning,
  });

  final String word;

  final String meaning;

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<WordDefaultMeaning> {
  String word = "";
  String meaning = "";

  @override
  void initState() {
    super.initState();
    word = widget.word;
    meaning = widget.meaning;
  }

  Widget get buildWordHeaderRow {
    List<Widget> children = [
      Expanded(
          child: Text(word, maxLines: 2, style: const TextStyle(fontSize: 20))),
    ];
    if (!word.contains("_") && !word.contains(" ") && !word.contains(",")) {
      children.addAll([
        buildInkWell(context, word, 0),
        const SizedBox(width: 5),
        buildInkWell(context, word, 1),
        const SizedBox(width: 5),
        buildInkWell(context, word, 2),
        const SizedBox(width: 5),
        buildInkWell(context, word, 3),
      ]);
    }
    return Row(children: children);
  }

  void loopUp(String selectText) async {
    String tempWord = selectText;
    String m = await handler.defaultWordMeaning(tempWord);
    if (m == "") {
      tempWord = await handler.dictWordQueryLink(tempWord);
      m = await handler.defaultWordMeaning(tempWord);
    }
    if (m == '') {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('无结果: $word', maxLines: 1, overflow: TextOverflow.ellipsis),
        duration: const Duration(milliseconds: 2000),
      ));
      return;
    }

    myPrint(word);
    meaning = fixDefaultMeaning(m);
    word = tempWord;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final col = Column(
      children: [
        buildWordHeaderRow,
        Flexible(
            child: SingleChildScrollView(
                child: SelectableText(
          meaning,
          contextMenuBuilder:
              (BuildContext context, EditableTextState editableTextState) {
            final textEditingValue = editableTextState.textEditingValue;
            final TextSelection selection = textEditingValue.selection;
            final buttonItems = editableTextState.contextMenuButtonItems;
            if (!selection.isCollapsed) {
              final selectText =
                  selection.textInside(textEditingValue.text).trim();
              if (!selectText.contains(" ")) {
                buttonItems.add(ContextMenuButtonItem(
                    onPressed: () {
                      loopUp(selectText);
                    },
                    label: "Lookup"));
              }
            }
            return AdaptiveTextSelectionToolbar.buttonItems(
              buttonItems: buttonItems,
              anchors: editableTextState.contextMenuAnchors,
            );
          },
        )))
      ],
    );
    return Padding(padding: const EdgeInsets.all(10), child: col);
  }
}

String fixDefaultMeaning(String meaning) {
  meaning = meaning.replaceAll("*", "\n*");
  List<String> result = [];
  final ss = meaning.split(". ");
  for (int i = 0; i < ss.length; i++) {
    final s = ss[i];
    if (s == "") continue;
    if (s.startsWith(RegExp(r'^\d+ '))) {
      if (s.endsWith('.')) {
        result.add("\n\n$s ");
      } else {
        result.add("\n\n$s. ");
      }
      continue;
    }
    if (s.endsWith('.')) {
      result.add("$s ");
    } else {
      result.add("$s. ");
    }
  }
  meaning = result.join('');
  return meaning;
}
