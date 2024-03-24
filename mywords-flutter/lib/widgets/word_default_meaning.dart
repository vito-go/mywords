import 'package:flutter/material.dart';
import 'package:mywords/widgets/word_header_row.dart';
import 'package:mywords/libso/handler_for_native.dart'
if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';

class WordDefaultMeaning extends StatefulWidget {
  const WordDefaultMeaning(
      {super.key, required this.word, required this.meaning});

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


  @override
  Widget build(BuildContext context) {
    final col = Column(
      children: [
        WordHeaderRow(word: word, key: UniqueKey()),
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
                    onPressed: () async {
                      String tempWord = selectText;
                      String m = await handler.dictWordQuery(tempWord);
                      if (m == "") {
                        tempWord = await handler.dictWordQueryLink(tempWord);
                        m = await handler.dictWordQuery(tempWord);
                      }
                      if (m == '') {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('无结果: $word',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          duration: const Duration(milliseconds: 2000),
                        ));
                        return;
                      }
                      meaning = fixDefaultMeaning(m);
                      word = tempWord;
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {});
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
