import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/global.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/common/queue.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/pages/article_archived_list.dart';
import 'package:mywords/pages/known_words.dart';
import 'package:mywords/pages/parse_local_file.dart';
import 'package:mywords/pages/proxy.dart';
import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/util/navigator.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../util/util.dart';
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
    final data = await handler.knownWordsCountMap();
    levelCountMap = data;
    setState(() {});
  }

  Widget buildListTileVacuumDB() {
    return ListTile(
      title: const Text('Vacuum DB'),
      subtitle: Text(formatSize(handler.dbSize().data ?? 0)),
      // trailing: vacuums the database
      onTap: () {
        setState(() {});
      },
      trailing: IconButton(
          onPressed: () async {
            final before = handler.dbSize().data ?? 0;
            final resp = await compute((m) => handler.vacuumDB(), null);
            myPrint("vacuumDB: ${resp.data}");
            final after = handler.dbSize().data ?? 0;
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Vacuum DB successfully! freed: ${formatSize(before - after)}'),
            ));
            Navigator.pop(context);
            // if (before != after) {
            //   setState(() {});
            // }
          },
          icon: const Icon(Icons.cleaning_services)),
      leading: const Icon(Icons.data_usage),
    );
  }

  Widget buildListTileWebDictPort() {
    final url = "http://127.0.0.1:${Global.webDictRunPort}/_query?word=hello";
    return ListTile(
      title: const Text('WebDict'),
      subtitle: Text(url),
      // trailing: vacuums the database
      onTap: () {
        launchUrlString(url);
      },
      leading: const Icon(Icons.http),
    );
  }

  changeTheme() {
    SimpleDialog simpleDialog = SimpleDialog(
      title: const Text('ThemeMode'),
      children: [
        RadioListTile(
          value: ThemeMode.system,
          onChanged: (value) {
            Navigator.of(context).pop();
            prefs.themeMode = ThemeMode.system;
            produceEvent(EventType.updateTheme, ThemeMode.system);
          },
          title: const Text('Auto'),
          groupValue: prefs.themeMode,
        ),
        RadioListTile(
          value: ThemeMode.dark,
          onChanged: (value) {
            Navigator.of(context).pop();
            prefs.themeMode = ThemeMode.dark;
            produceEvent(EventType.updateTheme, ThemeMode.dark);
          },
          title: const Text("dark"),
          groupValue: prefs.themeMode,
        ),
        RadioListTile(
          value: ThemeMode.light,
          onChanged: (value) {
            Navigator.of(context).pop();
            prefs.themeMode = ThemeMode.light;
            produceEvent(EventType.updateTheme, ThemeMode.light);
          },
          title: const Text("light"),
          groupValue: prefs.themeMode,
        ),
        // SimpleDialogOption(
        //   child: Text("跟随系统"),
        //   onPressed: () {
        //     Navigator.pop(context, "简单对话框1");
        //   },
        // ),
      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return simpleDialog;
        });
  }

  @override
  void initState() {
    super.initState();
    initLevelMap();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget get header => ListTile(
        title: Text("已知单词总数量: $totalCount"),
        subtitle: Text(levelText),
        trailing: IconButton(
            onPressed: () {
              // changeTheme();
              // return;
              if (prefs.themeMode == ThemeMode.light) {
                prefs.themeMode = ThemeMode.dark;
                produceEvent(EventType.updateTheme, ThemeMode.dark);
              } else {
                prefs.themeMode = ThemeMode.light;
                produceEvent(EventType.updateTheme, ThemeMode.light);
              }
              setState(() {});
            },
            icon: prefs.themeMode == ThemeMode.light
                ? const Icon(Icons.nightlight_round)
                : const Icon(Icons.sunny)),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Drawer(
            child: ListView(
      children: [
        header,
        const Divider(),
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
        buildListTileVacuumDB(),
        buildListTileWebDictPort(),
      ],
    )));
  }
}
