import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';
import 'package:mywords/util/local_cache.dart';
import 'package:mywords/widgets/word_default_meaning.dart';
import 'package:mywords/widgets/word_html.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'dart:io';

void _queryWordInDictWithMobile(BuildContext context, String word) async {
  String htmlBasePath = await handler.finalHtmlBasePathWithOutHtml(word);
  if (htmlBasePath == '') {
    word = await handler.dictWordQueryLink(word);
    htmlBasePath = await handler.finalHtmlBasePathWithOutHtml(word);
  }
  if (htmlBasePath == '') {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('无结果: $word', maxLines: 1, overflow: TextOverflow.ellipsis),
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

void _queryWordInDictNotMobile(BuildContext context, String word) async {
  String url = await handler.getUrlByWord(word);
  if (url.isEmpty) {
    word = await handler.dictWordQueryLink(word);
    url = await handler.finalHtmlBasePathWithOutHtml(word);
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

void queryWordInDict(BuildContext context, String word) async {
  if (kIsWeb) {
    _queryWordInDictNotMobile(context, word);
    return;
  }
  if (Platform.isAndroid || Platform.isIOS) {
    _queryWordInDictWithMobile(context, word);
    return;
  }

  // Desktop;
  _queryWordInDictNotMobile(context, word);
}

void showWordWithDefault(BuildContext context, String word) async {
  String meaning = await handler.dictWordQuery(word);
  if (meaning == "") {
    word = await handler.dictWordQueryLink(word);
    meaning = await handler.dictWordQuery(word);
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

void showWord(BuildContext context, String word) async {
  LocalCache.defaultDictBasePath ??=
      ((await handler.getDefaultDict()).data ?? '');
  if (LocalCache.defaultDictBasePath == "") {
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

bool isWordParticular(int element) {
  if ((element >= 97 && element <= 122) ||
      (element >= 65 && element <= 90) ||
      (element == 45)) {
    return true;
  }
  return false;
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
      if (isWordParticular(runes[i])) {
        start = i;
        break;
      }
    }
    for (var i = runes.length - 1; i >= 0; i--) {
      if (isWordParticular(runes[i])) {
        end = i + 1;
        break;
      }
    }
    final word = String.fromCharCodes(runes.sublist(start, end));
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
