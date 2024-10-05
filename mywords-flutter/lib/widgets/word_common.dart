import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler.dart';

import 'package:mywords/widgets/word_default_meaning.dart';

import 'package:mywords/widgets/word_webview_for_mobile.dart'
    if (dart.library.html) 'package:mywords/widgets/word_webview_for_web.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'dart:io';

import '../common/global.dart';
import '../common/queue.dart';
import '../util/util.dart';

void _queryWordInDictWithMobile(BuildContext context, String word) async {
  bool exist = await handler.existInDict(word);
  if (!exist) {
    word = await handler.dictWordQueryLink(word);
    exist = await handler.existInDict(word);
  }
  if (!exist) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('无结果: $word', maxLines: 1, overflow: TextOverflow.ellipsis),
      duration: const Duration(milliseconds: 2000),
    ));
    return;
  }
  if (!context.mounted) return;
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

void queryWordInDict(BuildContext context, String word) async {
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    _queryWordInDictWithMobile(context, word);
    return;
  }
  // Desktop;
  // FIXME 后续版本计划不再支持桌面客户端版本, 请使用桌面网页版
  // Deprecated: subsequent versions plan to no longer support desktop client versions, please use the desktop web version
  final url = "http://127.0.0.1:${Global.webDictRunPort}/_query?word=$word";
  launchUrlString(url);
  // throw "Unsupported platform, please use web version";
}

void showWordWithDefault(BuildContext context, String word) async {
  String meaning = await handler.defaultWordMeaning(word);
  if (meaning == "") {
    word = await handler.dictWordQueryLink(word);
    meaning = await handler.defaultWordMeaning(word);
  }
  if (meaning == '') {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('无结果: $word', maxLines: 1, overflow: TextOverflow.ellipsis),
      duration: const Duration(milliseconds: 2000),
    ));
    return;
  }
  meaning = fixDefaultMeaning(meaning);
  if (!context.mounted) return;
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
  FocusManager.instance.primaryFocus?.unfocus();
  final defaultDictId = await handler.getDefaultDictId();
  if (!context.mounted) return;
  if (defaultDictId == 0) {
    showWordWithDefault(context, word);
    return;
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
  final normalColor = Theme.of(context).textTheme.bodyMedium?.color;
  List<InlineSpan>? children = [];
  List<String> infos = text.split(" ");
  for (var i = 0; i < infos.length; i++) {
    Color? color = normalColor;
    final info = infos[i];
    FontWeight fontWeight = FontWeight.normal;
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
    if (tokens.indexWhere((element) => word.startsWith(element)) != -1) {
      color = Colors.green;
      fontWeight = FontWeight.bold;
    }
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

InkWell buildInkWell(BuildContext context, String word, int showLevel) {
  int realLevel = Global.allKnownWordsMap[word] ?? 0;
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
      onTap: () async {
        final respData = await handler.updateKnownWordLevel(word, showLevel);
        if (respData.code != 0) {
          myToast(context, respData.message);
          return;
        }
        if (showLevel == 0) {
          Global.allKnownWordsMap.remove(word);
        } else {
          Global.allKnownWordsMap[word] = showLevel;
        }
        produceEvent(EventType.updateKnownWord,
            <String, dynamic>{"word": word, "level": showLevel});
      });
}
