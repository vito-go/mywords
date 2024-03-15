import 'dart:convert';

import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/pages/article_archived_list.dart';
import 'package:mywords/pages/known_words.dart';
import 'package:mywords/pages/parse_local_file.dart';
import 'package:mywords/pages/proxy.dart';
import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/path.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/widgets/restart_app.dart';

import '../common/global_event.dart';
import '../libso/funcs.dart';
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

  void initLevelMap() {
    // map[server.WordKnownLevel]int
    final resultC = knownWordsCountMap();
    final RespData<Map<String, dynamic>> respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()) ?? {},
        (json) => json as Map<String, dynamic>);
    myPrint(resultC.toDartString());
    malloc.free(resultC);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    levelCountMap = respData.data ?? {};
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

  void parseLocalFiles() async {
    // todo
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        initialDirectory: getDefaultDownloadDir(),
        allowMultiple: false,
        withReadStream: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'PDF', 'txt', 'TXT']);
    if (result == null) {
      return;
    }
    final files = result.files;
    if (files.isEmpty) {
      return;
    }
    final file = files[0];
    if (file.path == null) {
      return;
    }

    final respData = await compute(
        (message) => computeRestoreFromBackUpData(message),
        <String, dynamic>{});
    if (respData.code != 0) {
      myToast(context, "恢复失败!\n${respData.message}");
      return;
    }
    myToast(context, "恢复成功");
    addToGlobalEvent(
        GlobalEvent(eventType: GlobalEventType.parseAndSaveArticle));
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
