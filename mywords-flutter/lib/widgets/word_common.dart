import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/pages/word_html.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../libso/dict.dart';
import '../libso/funcs.dart';
import '../util/navigator.dart';
import 'word_list.dart';
import 'dart:io';

void queryWordInDict(BuildContext context, String word,
    {void Function()? whenUpdateKnownWords}) {
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
    pushTo(context, WordHtml(word: word));
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

Widget highlightText(String text, List<String> tokens,
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