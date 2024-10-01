import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mywords/common/global.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/pages/home.dart';

import 'common/prefs/prefs.dart';
import 'common/queue.dart';
import 'common/read_message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initGlobalPrefs();
  await handler.initLib();
  isolateLoopReadMessage(); // 开启后无法热重载,为什么? 可能是因为热重载会重新加载所有的代码，而isolateLoopReadMessage()是一个无限循环的函数
  await Global.init();
  runApp(const MyApp());
}

class BannerObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final context = route.navigator?.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).removeCurrentMaterialBanner();
    super.didPush(route, previousRoute);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  void eventHandler(Event event) {
    if (event.eventType == EventType.updateTheme) {
      setState(() {});
    }
  }

  StreamSubscription<Event>? eventConsumer;

  @override
  dispose() {
    super.dispose();
    eventConsumer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    eventConsumer = consume(eventHandler);
  }

  @override
  Widget build(BuildContext context) {
    final inversePrimary = Theme.of(context).colorScheme.inversePrimary;
    return MaterialApp(
      // navigatorObservers: [BannerObserver()],
      title: 'mywords',
      // debugShowCheckedModeBanner: false,
      themeMode: prefs.themeMode,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(color: Colors.black54),
        drawerTheme: const DrawerThemeData(),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xfff1d296),
          surface: Color(0xff151515),
        ),
      ),
      theme: ThemeData(
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.orange.shade50,
        ),
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(color: Colors.orangeAccent),
        colorScheme: ColorScheme.fromSeed(
          primary: Colors.orange,
          seedColor: Colors.deepOrange,
          surface: Colors.orange.shade50,
        ),
        useMaterial3: true,
      ),
      home: const Home(),
      scrollBehavior: MyCustomScrollBehavior(),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus
        // etc.
      };
}
