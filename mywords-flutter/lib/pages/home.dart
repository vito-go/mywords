import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/common/queue.dart';
import 'package:mywords/pages/sources.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/util_native.dart'
    if (dart.library.html) 'package:mywords/util/util_web.dart';
import 'package:mywords/widgets/tool.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../common/global.dart';
import '../libso/handler.dart';
import '../util/navigator.dart';
import '../util/util.dart';
import 'article_list_page.dart';
import 'lookup_word.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _State();
}

class _State extends State<Home> {
  final PageController _pageController =
      PageController(initialPage: prefs.defaultHomeIndex);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  int get idx => prefs.defaultHomeIndex;

  set idx(int v) => prefs.defaultHomeIndex = v;
  List<Widget> homePages = [
    const ArticleListPage(),
    const LoopUpWord(),
    const MyTool()
  ];
  final List<BottomNavigationBarItem> bottomBarItems = [
    const BottomNavigationBarItem(
        label: ("Article"), icon: Icon(Icons.article)),
    // const BottomNavigationBarItem(
    //     label: ("词典"), icon: Icon(Icons.find_in_page_outlined)),
    const BottomNavigationBarItem(
        label: ("Dictionary"), icon: Icon(Icons.find_in_page_outlined)),
    // const BottomNavigationBarItem(label: ("工具"), icon: Icon(Icons.settings)),
    const BottomNavigationBarItem(label: ("Tool"), icon: Icon(Icons.settings)),
  ];

  Widget get themeIconButton {
    return IconButton(
        onPressed: () {
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
            : const Icon(Icons.sunny));
  }

  void aboutOnTap() async {
    const applicationName = "mywords";
    final buildInfo =
        '${Global.goBuildInfoString}\n${const String.fromEnvironment("FLUTTER_VERSION", defaultValue: "")}';
    if (!context.mounted) return;
    final width = getPlatformWebWidth(context);
    showAboutDialog(
      context: context,
      applicationName: applicationName,
      applicationIcon: InkWell(
        child: CircleAvatar(child: Image.asset("logo.png")),
        onTap: () async {},
      ),
      applicationVersion: "version: ${Global.version}",
      applicationLegalese: '© All rights reserved',
      children: [
        const SizedBox(height: 5),
        Row(
          children: [
            const Text("author: "),
            Flexible(
                child: InkWell(
                    child: const Text("liushihao888@gmail.com",
                        style: TextStyle(color: Colors.blue)),
                    onTap: () {
                      copyToClipBoard(context, "liushihao888@gmail.com");
                    })),
          ],
        ),
        const Text("address: California, USA"),
        Row(
          children: [
            const Text("github: "),
            Flexible(
                child: InkWell(
                    child: const Text("https://github.com/vito-go/mywords",
                        style: TextStyle(color: Colors.blue)),
                    onTap: () {
                      launchUrlString("https://github.com/vito-go/mywords");
                    })),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          child: SizedBox(width: width, child: Text(buildInfo)),
          onTap: () {
            copyToClipBoard(context, buildInfo);
          },
        )
      ],
    );
  }

  Widget get refreshAllButton => IconButton(
      onPressed: () async {
        produceEvent(EventType.updateLineChart);
        produceEvent(EventType.updateArticleList);
        produceEvent(EventType.articleListScrollToTop, 1);
        produceEvent(EventType.updateKnownWord); // notify
        final respData = await handler.allKnownWordsMap();
        if (respData.code != 0) {
          throw Exception("allKnownWordsMap error: ${respData.message}");
        }
        Global.allKnownWordsMap = respData.data ?? {};
        myToast(context, "Successfully!");
      },
      icon: const Icon(Icons.refresh));

  List<Widget> get actions {
    final List<Widget> result = [];
    if (platformIsMobileClient()) {
      result.add(IconButton(
        icon: const Icon(Icons.web),
        onPressed: () {
          pushTo(context, Sources());
        },
      ));
    }
    result.add(refreshAllButton);
    result.add(IconButton(
        onPressed: aboutOnTap, icon: const Icon(Icons.help_outline)));
    result.add(themeIconButton);
    return result;
  }

  BottomNavigationBar get bottomBar => BottomNavigationBar(
        items: bottomBarItems,
        type: BottomNavigationBarType.fixed,
        currentIndex: idx,
        onTap: (int i) {
          if (idx == i && i == 0) {
            // 滚动置顶
            produceEvent(EventType.articleListScrollToTop, 1);
          }
          if (idx == i) return;
          _pageController.jumpToPage(i);
          idx = i;
          prefs.defaultHomeIndex = idx;
          setState(() {});
          return;
        },
      );

  @override
  Widget build(BuildContext context) {
    return getScaffold(
      context,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("mywords"),
        // toolbarHeight: 48,
        // centerTitle: true,
        actions: actions,
      ),
      body: PageView(
        // index: idx,
        pageSnapping: false,
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            FocusManager.instance.primaryFocus?.unfocus();
            idx = index;
            prefs.defaultHomeIndex = index;
          });
        },
        // index: idx,
        children: homePages,
      ),
      // drawer: const MyDrawer(),
      bottomNavigationBar: bottomBar,
      drawerEnableOpenDragGesture: true,
    );
  }
}
