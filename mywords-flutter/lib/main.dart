import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mywords/common/global.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/pages/home.dart';
import 'package:mywords/widgets/restart_app.dart';

import 'common/prefs/prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initGlobalPrefs();
  await handler.initLib();
  await Global.init();
  runApp(const RestartApp(child: MyApp()));
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // navigatorObservers: [BannerObserver()],
      title: 'mywords',
      // debugShowCheckedModeBanner: false,
      // themeMode: prefs.themeMode,
      themeMode: ThemeMode.light,
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(color: Colors.white70),
          drawerTheme: const DrawerThemeData(
            backgroundColor: Colors.grey,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xfff1d296),
          )),

      theme: ThemeData(
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.orange.shade50,
        ),
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(color: Colors.black),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          background: Colors.orange.shade50,
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
