import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/common/queue.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/web.dart';
import 'package:mywords/widgets/tool.dart';
import '../common/global.dart';
import '../util/util.dart';
import 'article_list_page.dart';
import 'lookup_word.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _State();
}

const appVersion = "3.0.0";

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
    const BottomNavigationBarItem(label: ("文章"), icon: Icon(Icons.article)),
    const BottomNavigationBarItem(
        label: ("词典"), icon: Icon(Icons.find_in_page_outlined)),
    const BottomNavigationBarItem(label: ("工具"), icon: Icon(Icons.settings)),
  ];

  void aboutOnTap() async {
    const applicationName = "mywords";
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: applicationName,
      applicationIcon: InkWell(
        child: CircleAvatar(child: Image.asset("logo.png")),
        onTap: () async {},
      ),
      applicationVersion: "version: $appVersion",
      applicationLegalese: '© All rights reserved',
      children: [
        const SizedBox(height: 5),
        const Text("author: liushihao888@gmail.com"),
        const SizedBox(height: 2),
        Text(
            "version: ${Global.version}\n\n${Global.goBuildInfoString}\n${const String.fromEnvironment("FLUTTER_VERSION", defaultValue: "")}"),
      ],
    );
  }

  List<Widget> get actions {
    return [
      IconButton(
          onPressed: () {
            produce(Event(eventType: EventType.updateLineChart));
            produce(Event(eventType: EventType.updateArticleList));
            produce(
                Event(eventType: EventType.articleListScrollToTop, param: 1));
            myToast(context, "Successfully!");
          },
          icon: const Icon(Icons.refresh)),
      IconButton(onPressed: aboutOnTap, icon: const Icon(Icons.help_outline)),
      // IconButton(onPressed: changeTheme, icon: const Icon(Icons.sunny)),
    ];
  }

  BottomNavigationBar get bottomBar => BottomNavigationBar(
        items: bottomBarItems,
        type: BottomNavigationBarType.fixed,
        currentIndex: idx,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (int i) {
          if (idx == i && i == 0) {
            // 滚动置顶
            produce(
                Event(eventType: EventType.articleListScrollToTop, param: 1));
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
      bottomNavigationBar: SizedBox(width: getPlatformWebWidth(context), child: bottomBar),
      drawerEnableOpenDragGesture: true,
    );
  }
}
