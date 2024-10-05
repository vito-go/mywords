import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
 import 'package:mywords/util/util_native.dart' if (dart.library.html) 'package:mywords/util/util_web.dart';

bool platFormIsMobile() {
  if (kIsWeb) {
    return false;
  }
  if (Platform.isAndroid || Platform.isIOS) {
    return true;
  }
  return false;
}

Widget getScaffold(
  BuildContext context, {
  required Widget body,
  final PreferredSizeWidget? appBar,
  final Widget? drawer,
  final Widget? bottomNavigationBar,
  final bool drawerEnableOpenDragGesture = true,
  final double noMobileWidthRate = 0.35,
}) {
  final Widget adjustedBody;

  if (kIsWeb) {
    if (platFormWebIsMobile()) {
      adjustedBody = body;
    } else {
      // desktop web
      double width = getPlatformWebWidth(context);
      adjustedBody = Center(child: SizedBox(width: width, child: body));
    }
  } else {
    adjustedBody = body;
  }

  return Scaffold(
    body: adjustedBody,
    appBar: appBar,
    bottomNavigationBar: bottomNavigationBar,
    drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
    drawer: drawer,
  );
}
