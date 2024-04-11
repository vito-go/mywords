
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler.dart';

import 'package:mywords/widgets/word_list.dart';
import 'package:mywords/util/get_scaffold.dart';

class KnownWords extends StatefulWidget {
  const KnownWords({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<KnownWords> {
  int showLevel = prefs.showWordLevel;

  @override
  void initState() {
    super.initState();
  }

  List<Widget> actions() {
    return [];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: actions(),
      title: const Text("我的单词库"),
    );

    final body = WordList(
        showLevel: showLevel, getLevelWordsMap: handler.allKnownWordMap);

    return getScaffold(
      context,
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: body,
      ),
    );
  }
}
