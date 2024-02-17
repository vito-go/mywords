import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';

import '../libso/funcs.dart';

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

void slideToOperate(
    BuildContext context, String fileName, void Function() setState,
    {milliseconds = const Duration(milliseconds: 4000),
    required String toast}) {
  final t = Timer(Duration(milliseconds: milliseconds), () async {
    archiveGobFile(fileName);
  });
  // Then show a snackbar.
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(toast, maxLines: 1, overflow: TextOverflow.ellipsis),
    action: SnackBarAction(
        label: "撤销",
        onPressed: () {
          t.cancel();
          setState();
          return;
        }),
  ));
}

Widget getBackgroundChild(String label, IconData iconData) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(iconData, color: Colors.white),
      Text(label, style: const TextStyle(color: Colors.white))
    ],
  );
}

Widget getBackgroundWidget(BuildContext context,
    {required Widget left, required Widget right}) {
  List<Widget> children = [];
  children.add(left);
  children.add(const Expanded(child: Text("")));
  children.add(right);
  final backgroundWidget = Container(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
          padding: const EdgeInsets.only(right: 20, left: 20),
          child: Row(children: children)));
  return backgroundWidget;
}
