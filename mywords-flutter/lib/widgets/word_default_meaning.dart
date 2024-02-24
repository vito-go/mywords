import 'package:flutter/material.dart';
import 'package:mywords/widgets/word_header_row.dart';
import 'package:mywords/widgets/word_list.dart';

import '../libso/funcs.dart';

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

  int get l => queryWordLevel(word);

  @override
  Widget build(BuildContext context) {
    final col = Column(
      children: [
        WordHeaderRow(word: word,key: UniqueKey()),
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
                      String tempWord = selectText;
                      String m = dictWordQuery(tempWord);
                      if (m == "") {
                        tempWord = dictWordQueryLink(tempWord);
                        m = dictWordQuery(tempWord);
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
