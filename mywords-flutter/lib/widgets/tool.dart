import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/global.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/common/queue.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/pages/article_archived_list.dart';
import 'package:mywords/pages/known_words.dart';
import 'package:mywords/pages/proxy.dart';
import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/widgets/private_ip.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../pages/dict_database.dart';
import '../pages/restore_data.dart';
import '../pages/share_data.dart';
import '../util/util.dart';

class MyTool extends StatefulWidget {
  const MyTool({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyToolState();
  }
}

class MyToolState extends State<MyTool> with AutomaticKeepAliveClientMixin {
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
    // return "L1: $count1  L2: $count2  L3: $count3";
    return "L1: $count1  L2: $count2  L3: $count3";
  }

  StreamSubscription<Event>? eventConsumer;

  void initLevelMap() async {
    final data = await handler.knownWordsCountMap();
    levelCountMap = data;
    dbSize = (await handler.dbSize()).data ?? 0;
    defaultDictId = await handler.getDefaultDictId();
    webOnlineClose = await handler.getWebOnlineClose();
    ips = (await handler.getIPv4s()) ?? [];
    setState(() {});
  }

  int dbSize = 0;

  Widget buildListTileVacuumDB() {
    return ListTile(
      title: const Text('Vacuum DB'),
      subtitle: Text(formatSize(dbSize)),
      // trailing: vacuums the database
      onTap: () {
        setState(() async {
          dbSize = (await handler.dbSize()).data ?? 0;
        });
      },
      trailing: IconButton(
          onPressed: () async {
            final before = (await handler.dbSize()).data ?? 0;
            final resp = await compute((m) => handler.vacuumDB(), null);
            if (resp.code != 0) {
              myToast(context, resp.message);
              return;
            }
            myPrint("vacuumDB: ${resp.data}");
            final after = (await handler.dbSize()).data ?? 0;
            if (!context.mounted) {
              return;
            }
            if (kIsWeb) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Vacuum DB successfully!'),
              ));
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Vacuum DB successfully! freed: ${formatSize(before - after)}'),
            ));
          },
          icon: const Icon(Icons.cleaning_services)),
      leading: const Icon(Icons.data_usage),
    );
  }

  Widget buildListTileWebDictPort() {
    final url = "http://127.0.0.1:${Global.webDictRunPort}/_query?word=hello";
    return ListTile(
      title: const Text('WebDict API'),
      subtitle: Text(url),
      // trailing: vacuums the database
      onTap: () {
        launchUrlString(url);
      },
      leading: const Icon(Icons.api),
     );
  }

  Widget buildListTileRestoreFromOld() {
    return ListTile(
      title: const Text('从旧版本恢复数据'),
      // trailing: vacuums the database
      onTap: () async {
        // final respData = await handler.restoreFromOldVersionData();
        // compute handler.restoreFromOldVersionData
        final respData =
            await compute((m) => handler.restoreFromOldVersionData(), null);
        if (respData.code != 0) {
          myToast(context, respData.message);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('从旧版本恢复数据成功!'),
        ));
      },
      leading: const Icon(Icons.restore_page),
    );
  }

  void showBuildInfo() {
    //show  handler.goRuntimeInfo()
    final info = Global.goBuildInfoString;
    showDialog(
        context: context,
        builder: (context) {
          const flutterVersion =
              String.fromEnvironment("FLUTTER_VERSION", defaultValue: "");
          // show flutterVersion and info, support copy and scroll if needed
          return AlertDialog(
            title: const Text("Build Info"),
            content: SingleChildScrollView(
              child: Text(
                  "version: ${Global.version}\n\n${Global.goBuildInfoString}\n${const String.fromEnvironment("FLUTTER_VERSION", defaultValue: "")}"),
            ),
            actions: [
              // Copy
              TextButton(
                  onPressed: () {
                    copyToClipBoard(context, "$info\n$flutterVersion");
                  },
                  child: const Text("Copy")),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Close")),
            ],
          );
        });
  }

  changeTheme() {
    SimpleDialog simpleDialog = SimpleDialog(
      title: const Text('ThemeMode'),
      children: [
        RadioListTile(
          value: ThemeMode.system,
          onChanged: (value) {
            prefs.themeMode = ThemeMode.system;
            produceEvent(EventType.updateTheme, ThemeMode.system);
          },
          title: const Text('Auto'),
          groupValue: prefs.themeMode,
        ),
        RadioListTile(
          value: ThemeMode.dark,
          onChanged: (value) {
            prefs.themeMode = ThemeMode.dark;
            produceEvent(EventType.updateTheme, ThemeMode.dark);
          },
          title: const Text("dark"),
          groupValue: prefs.themeMode,
        ),
        RadioListTile(
          value: ThemeMode.light,
          onChanged: (value) {
            prefs.themeMode = ThemeMode.light;
            produceEvent(EventType.updateTheme, ThemeMode.light);
          },
          title: const Text("light"),
          groupValue: prefs.themeMode,
        ),
      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return simpleDialog;
        });
  }

  void eventHandler(Event event) async {
    switch (event.eventType) {
      case EventType.updateArticleList:
        break;
      case EventType.syncData:
        break;
      case EventType.updateKnownWord:
        break;
      case EventType.articleListScrollToTop:
      case EventType.updateLineChart:
        break;
      case EventType.updateTheme:
        break;
      case EventType.updateDict:
        defaultDictId = await handler.getDefaultDictId();

        setState(() {});
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    initLevelMap();
    eventConsumer = consume(eventHandler);
  }

  @override
  void dispose() {
    super.dispose();
    myPrint("dispose mytool");
  }

  List<String> ips = [];

  Widget get header => ListTile(
      // title: Text("已知单词总数量: $totalCount"), 英语化
      title: Text("Known Words: $totalCount"),
      subtitle: Text(levelText),
      onTap: () {
        pushTo(context, const KnownWords());
      },
      trailing: const Icon(Icons.navigate_next));

  Widget buildInfo() {
    final Widget buildInfoLeading;
    if (kIsWeb) {
      buildInfoLeading = const Icon(Icons.devices_other);
    } else if (Platform.isAndroid) {
      buildInfoLeading = const Icon(Icons.android);
    } else if (Platform.isIOS) {
      buildInfoLeading = const Icon(Icons.phone_iphone);
    } else if (Platform.isMacOS) {
      buildInfoLeading = const Icon(Icons.desktop_mac);
    } else if (Platform.isLinux) {
      buildInfoLeading = const Icon(Icons.computer);
    } else if (Platform.isWindows) {
      buildInfoLeading = const Icon(Icons.desktop_windows);
    } else {
      buildInfoLeading = const Icon(Icons.devices_other);
    }
    return ListTile(
      title: const Text('Build Info'),
      onTap: showBuildInfo,
      leading: buildInfoLeading,
      trailing: const Icon(Icons.navigate_next),
    );
  }

  bool webOnlineClose = false;


  Widget get webOnlineListTile {
    String message = "";
    if (ips.isNotEmpty) {
      String url = "\n";
      for (var ip in ips) {
        url += "http://$ip:${Global.webOnlinePort}/web/\n";
      }

      // message = "you can open the url ${url}in browser with other devices"; // add following
      message =
          "you can open one of the urls ${url}in browser with other devices";
    } else {
      message =
          "you can open the url http://127.0.0.1:${Global.webOnlinePort}/web/ in browser with your device";
    }
    final toolTip = Tooltip(
      message: message,
      showDuration: const Duration(seconds: 8),
      triggerMode: TooltipTriggerMode.tap,
      child: const Icon(Icons.info),
    );
    return ListTile(
      title: const Text("Web Online"),
      leading: webOnlineClose ? const Icon(Icons.http) : toolTip,
      subtitle: webOnlineClose
          ? const Text("Web Online is closed")
          : Text("http://127.0.0.1:${Global.webOnlinePort}/web/"),
      onTap: () {
        if (webOnlineClose) {
          return;
        }
        launchUrlString("http://127.0.0.1:${Global.webOnlinePort}/web/");
      },
      trailing: Switch(
          value: !webOnlineClose,
          onChanged: (v) {
            webOnlineClose = !webOnlineClose;
            myPrint(webOnlineClose);
            handler.setWebOnlineClose(webOnlineClose);
            setState(() {});
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    myPrint("build MyTool");
    final List<Widget> children = [];
    // children.add(buildInfo());
    children.addAll([
      header,
      const Divider(),

      ListTile(
        // title: const Text("学习统计"),
        title: const Text("Learning Statistics"),
        leading: const Icon(Icons.stacked_line_chart),
        trailing: const Icon(Icons.navigate_next),
        onTap: () {
          pushTo(context, const StatisticChart());
        },
      ),
      ListTile(
        // title: const Text("已归档文章"),
        title: const Text("Archived Articles"),
        leading: const Icon(Icons.archive),
        trailing: const Icon(Icons.navigate_next),
        onTap: () {
          pushTo(context, const ArticleArchivedPage());
        },
      ),
      ListTile(
        // title: const Text("设置网络代理"),
        title: const Text("Network Proxy"),
        leading: const Icon(Icons.network_ping),
        trailing: const Icon(Icons.navigate_next),
        onTap: () {
          pushTo(context, const NetProxy());
        },
      ),
      ListTile(
        title: const Text("Share Data"),
        leading: const Icon(Icons.share),
        trailing: const Icon(Icons.navigate_next),
        onTap: () {
          pushTo(context, const SyncData());
        },
      ),
      ListTile(
        title: const Text("Sync Data"),
        leading: const Icon(Icons.sync),
        trailing: const Icon(Icons.navigate_next),
        onTap: () {
          pushTo(context, const RestoreData());
        },
      ),
      ListTile(
        // title: const Text("Dict Database"),
        title: const Text("Dictionary Database"),
        leading: const Icon(Icons.settings_suggest_outlined),
        trailing: const Icon(Icons.navigate_next),
        onTap: () {
          pushTo(context, const DictDatabase());
        },
      ),
      // buildListTileVacuumDB(),
    ]);

    children.add(webOnlineListTile);
    children.add(const PrivateIP());
    if (false) {
      children.add(buildListTileRestoreFromOld());
    }
    if (defaultDictId > 0) {
      children.add(buildListTileWebDictPort());
    }
    return ListView(children: children);
  }

  @override
  bool get wantKeepAlive => true;

  int defaultDictId = 0;
}
