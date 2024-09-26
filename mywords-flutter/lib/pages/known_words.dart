import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';

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
       actions: actions(),
      title: const Text("我的单词库"),
    );

    const body = WordList(createDay: 0);

    return getScaffold(
      context,
      appBar: appBar,
      body: const Padding(
        padding: EdgeInsets.all(8),
        child: body,
      ),
    );
  }
}
