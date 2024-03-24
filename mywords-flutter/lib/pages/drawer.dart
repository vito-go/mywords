import 'package:flutter/material.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';
import 'package:mywords/pages/article_archived_list.dart';
import 'package:mywords/pages/known_words.dart';
import 'package:mywords/pages/parse_local_file.dart';
import 'package:mywords/pages/proxy.dart';
import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/util/navigator.dart';

import 'dict_database.dart';
import 'restore_data.dart';
import 'share_data.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyDrawerState();
  }
}

class MyDrawerState extends State<MyDrawer> {
  Map<String, dynamic> levelCountMap = {};

  int get totalCount {
    int result = 0;
    for (var ele in levelCountMap.values) {
      if (ele is! int) {
        continue;
      }
      result += ele;
    }
    return result;
  }

  int get count1 => levelCountMap['1'] ?? 0;

  int get count2 => levelCountMap['2'] ?? 0;

  int get count3 => levelCountMap['3'] ?? 0;

  String get levelText {
    return "1级: $count1  2级: $count2  3级: $count3";
  }

  void initLevelMap() async {
    // map[server.WordKnownLevel]int
    final data = await handler.knownWordsCountMap();
    levelCountMap = data;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initLevelMap();
  }

  TextEditingController controller =
      TextEditingController(text: "mywords-backupdata");

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Drawer(
            // backgroundColor: Colors.orange.shade50,
            child: ListView(
      children: [
        DrawerHeader(
          child: ListTile(
            title: Text("已知单词总数量: $totalCount"),
            subtitle: Text(levelText),
          ),
        ),
        ListTile(
          title: const Text("我的单词库"),
          leading: const Icon(Icons.wordpress),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.pop(context);
            pushTo(context, const KnownWords());
          },
        ),
        ListTile(
          title: const Text("学习统计"),
          leading: const Icon(Icons.stacked_line_chart),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.pop(context);
            pushTo(context, const StatisticChart());
          },
        ),
        ListTile(
          title: const Text("解析本地文章"),
          leading: const Icon(Icons.article_outlined),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.pop(context);
            pushTo(context, const ParseLocalFile());
          },
        ),
        ListTile(
          title: const Text("已归档文章"),
          leading: const Icon(Icons.archive),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.pop(context);
            pushTo(context, const ArticleArchivedPage());
          },
        ),
        ListTile(
          title: const Text("设置网络代理"),
          leading: const Icon(Icons.network_ping),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.pop(context);
            pushTo(context, const NetProxy());
          },
        ),
        ListTile(
          title: const Text("分享/备份数据"),
          leading: const Icon(Icons.share),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.of(context).pop();
            pushTo(context, const SyncData());
          },
        ),
        ListTile(
          title: const Text("同步数据"),
          leading: const Icon(Icons.sync),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.of(context).pop();
            pushTo(context, const RestoreData());
          },
        ),
        ListTile(
          title: const Text("设置词典数据库"),
          leading: const Icon(Icons.settings_suggest_outlined),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.of(context).pop();
            pushTo(context, const DictDatabase());
          },
        ),
      ],
    )));
  }
}
