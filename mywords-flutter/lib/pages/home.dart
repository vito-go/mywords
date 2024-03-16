import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'drawer.dart';
import '../widgets/restart_app.dart';
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
  List<Widget> homePages = [const ArticleListPage(), const LoopUpWord()];
  final List<BottomNavigationBarItem> bottomBarItems = [
    const BottomNavigationBarItem(label: ("文章"), icon: Icon(Icons.article)),
    const BottomNavigationBarItem(
        label: ("词典"), icon: Icon(Icons.find_in_page_outlined)),
  ];

  void aboutOnTap() async {
    String version = "1.0.0";
    const applicationName = "mywords";
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: applicationName,
      applicationIcon: InkWell(
        // child: SizedBox(width: 50,height: 50,child: Image.asset("logo.png")),
        child: CircleAvatar(child: Image.asset("logo.png")),
        onTap: () async {},
      ),
      applicationVersion: "version: $version",
      applicationLegalese: '© All rights reserved',
      children: [
        const SizedBox(height: 5),
        const Text("author: liushihao888@gmail.com"),
        const SizedBox(height: 2),
        const Text("address: Beijing, China"),
      ],
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
            RestartApp.restart(context);
          },
          title: const Text('Auto'),
          groupValue: prefs.themeMode,
        ),
        RadioListTile(
          value: ThemeMode.dark,
          onChanged: (value) {
            Navigator.of(context).pop();
            prefs.themeMode = ThemeMode.dark;
            RestartApp.restart(context);
          },
          title: const Text("dark"),
          groupValue: prefs.themeMode,
        ),
        RadioListTile(
          value: ThemeMode.light,
          onChanged: (value) {
            Navigator.of(context).pop();
            prefs.themeMode = ThemeMode.light;
            RestartApp.restart(context);
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

  List<Widget> get actions {
    return [
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
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("MyWords"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
      drawer: const MyDrawer(),
      bottomNavigationBar: bottomBar,
      drawerEnableOpenDragGesture: true,
      onDrawerChanged: (t) {
        if (t) {}
      },
    );
  }
}
