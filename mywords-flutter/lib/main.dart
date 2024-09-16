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
  isolateLoopReadMessage();
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
  void globalEventHandler(Event event) {
    if (event.eventType == EventType.updateTheme) {
      setState(() {});
    }
  }

  StreamSubscription<Event>? globalEventSubscription;

  @override
  dispose() {
    super.dispose();
    globalEventSubscription?.cancel();
  }

  @override
  void initState() {
    super.initState();
    globalEventSubscription = consume(globalEventHandler);
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
        appBarTheme: AppBarTheme(color: inversePrimary),
        drawerTheme: const DrawerThemeData(
            // backgroundColor: Colors.grey,
            ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xfff1d296),
          surface: Color(0xff212121),
        ),
      ),
      theme: ThemeData(
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.orange.shade50,
        ),
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(color:inversePrimary),
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
