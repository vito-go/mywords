import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/widgets/word_default_meaning.dart';
import 'package:mywords/widgets/word_html.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../libso/dict.dart';
import '../libso/funcs.dart';
import 'dart:io';

void queryWordInDict(BuildContext context, String word) async {
  if (Platform.isAndroid || Platform.isIOS) {
    String htmlBasePath = finalHtmlBasePathWithOutHtml(word);
    if (htmlBasePath == '') {
      word = dictWordQueryLink(word);
      htmlBasePath = finalHtmlBasePathWithOutHtml(word);
    }
    if (htmlBasePath == '') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('无结果: $word', maxLines: 1, overflow: TextOverflow.ellipsis),
        duration: const Duration(milliseconds: 2000),
      ));
      return;
    }
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        builder: (BuildContext context) {
          return ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75),
            child: WordWebView(word: word),
          );
        });
    return;
  }
  String url = getUrlByWord(word);
  if (url.isEmpty) {
    word = dictWordQueryLink(word);
    url = finalHtmlBasePathWithOutHtml(word);
  }
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('无结果: $word', maxLines: 1, overflow: TextOverflow.ellipsis),
      duration: const Duration(milliseconds: 2000),
    ));
    return;
  }
  launchUrlString(url);
}

void showWordWithDefault(BuildContext context, String word) {
  String meaning = dictWordQuery(word);
  if (meaning == "") {
    word = dictWordQueryLink(word);
    meaning = dictWordQuery(word);
  }
  if (meaning == '') {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('无结果: $word', maxLines: 1, overflow: TextOverflow.ellipsis),
      duration: const Duration(milliseconds: 2000),
    ));
    return;
  }
  meaning = fixDefaultMeaning(meaning);
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: WordDefaultMeaning(word: word, meaning: meaning),
        );
      });
}

void showWord(BuildContext context, String word) {
  final defaultDict = getDefaultDict().data ?? '';
  if (defaultDict == '') {
    return showWordWithDefault(context, word);
  }
  queryWordInDict(context, word);
}

Widget buildSelectionWordArea(Widget child) {
  SelectedContent? selectedContent;
  return SelectionArea(
      contextMenuBuilder:
          (BuildContext context, SelectableRegionState selectableRegionState) {
        final buttonItems = selectableRegionState.contextMenuButtonItems;
        final content = selectedContent?.plainText;
        if (content != null) {
          final word = content.trim();
          if (!word.contains(" ")) {
            buttonItems.add((ContextMenuButtonItem(
                onPressed: () {
                  showWord(context, word);
                },
                label: "Lookup")));
          }
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
            buttonItems: buttonItems,
            anchors: selectableRegionState.contextMenuAnchors);
      },
      onSelectionChanged: (content) {
        selectedContent = content;
      },
      child: child);
}

Widget highlightTextSplitBySpace(
    BuildContext context, String text, List<String> tokens,
    {Widget Function(BuildContext context, EditableTextState editableTextState)?
        contextMenuBuilder}) {
  if (text == "") {
    return const Text("");
  }
  const fontSize = 14.0;
  // final bool isDark = prefs.themeMode == ThemeMode.dark;
  List<InlineSpan>? children = [];
  List<String> infos = text.split(" ");
  for (var i = 0; i < infos.length; i++) {
    Color color = prefs.isDark ? Colors.white70 : Colors.black;
    final info = infos[i];
    FontWeight fontWeight = FontWeight.normal;
    if (tokens.indexWhere((element) => info.startsWith(element)) != -1) {
      color = Colors.green;
      fontWeight = FontWeight.bold;
    }
    final runes = info.runes.toList();
    int start = 0;
    int? end;
    for (var i = 0; i < runes.length; i++) {
      final element = runes[i];
      if ((element >= 97 && element <= 122) ||
          (element >= 65 && element <= 90) ||
          (element == 45)) {
        start = i;
        break;
      }
    }
    for (var i = runes.length - 1; i >= 0; i--) {
      final element = runes[i];
      if ((element >= 97 && element <= 122) ||
          (element >= 65 && element <= 90) ||
          (element == 45)) {
        end = i + 1;
        break;
      }
    }
    final word = utf8.decode(runes.sublist(start, end), allowMalformed: true);
    children.add(TextSpan(
        text: info,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            showWord(context, word);
          },
        children: const [TextSpan(text: " ")],
        style: TextStyle(
            color: color,
            fontSize: fontSize.toDouble(),
            fontWeight: fontWeight)));
  }
  children.add(const TextSpan(
      text: "\n", style: TextStyle(fontWeight: FontWeight.normal)));
  final TextSpan textSpan = TextSpan(children: children);
  return SelectableText.rich(
    textSpan,
    contextMenuBuilder: contextMenuBuilder,
  );
}

Widget highlightTextSplitByToken(String text, List<String> tokens,
    {Widget Function(BuildContext context, EditableTextState editableTextState)?
        contextMenuBuilder}) {
  if (text == "") {
    return const Text("");
  }
  const fontSize = 14.0;
  // final bool isDark = prefs.themeMode == ThemeMode.dark;

  List<InlineSpan>? children = [];
  String token = '';
  List<String> infos = [];
  for (var i = 0; i < tokens.length; i++) {
    if (text.contains(tokens[i])) {
      token = tokens[i];
      infos = text.split(token);
      break;
    }
  }
  if (infos.isEmpty) {
    infos = [text];
  }
  for (var i = 0; i < infos.length; i++) {
    final info = infos[i];
    children.add(TextSpan(
        text: info,
        style: TextStyle(
            color: prefs.isDark ? Colors.white70 : Colors.black,
            fontSize: fontSize.toDouble(),
            fontWeight: FontWeight.normal)));
    if (i != infos.length - 1) {
      Color color = Colors.green;
      children.add(TextSpan(
          text: token,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: fontSize.toDouble(),
          )));
    }
  }
  children.add(const TextSpan(
      text: "\n", style: TextStyle(fontWeight: FontWeight.normal)));
  final TextSpan textSpan = TextSpan(children: children);
  return SelectableText.rich(
    textSpan,
    contextMenuBuilder: contextMenuBuilder,
  );
}
