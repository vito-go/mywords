import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/dict.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/widgets/word_list.dart';
import '../libso/funcs.dart';

class KnownWords extends StatefulWidget {
  const KnownWords({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<KnownWords> {
  int showLevel = prefs.showWordLevel;

  Map<int, List<String>> levelWordsMap = {};

  @override
  void initState() {
    super.initState();
    levelWordsMap = allKnownWordMap().data??{};
  }

  int get totalCount {
    return (levelWordsMap[1] ?? []).length +
        (levelWordsMap[2] ?? []).length +
        (levelWordsMap[3] ?? []).length;
  }

  Map<String, int> get levelWordsLengthMap {
    return {
      '1': (levelWordsMap[1] ?? []).length,
      '2': (levelWordsMap[2] ?? []).length,
      '3': (levelWordsMap[3] ?? []).length,
    };
  } //level: count

  List<Widget> actions() {
    return [
        IconButton(onPressed: (){
        final respData=fixMyKnownWords();
        if (respData.code!=0){
          myToast(context, respData.message);
          return;
        }
        myToast(context, "Successfully");
        setState(() {

        });

      }, icon: const Icon(Icons.refresh))
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: actions(),
      title: const Text("我的单词库"),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "文章词汇量分级 (0:陌生, 1级:认识, 2:了解, 3:熟悉)\n总数量:$totalCount, 1级: ${levelWordsLengthMap['1'] ?? 0}  2级: ${levelWordsLengthMap['2'] ?? 0}  3级: ${levelWordsLengthMap['3'] ?? 0}",
        ),
        const Divider(),
        Expanded(
            child: WordList(showLevel: showLevel, levelWordsMap: levelWordsMap))
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: body,
      ),
    );
  }
}
