import 'package:flutter/material.dart';
import 'package:mywords/util/util_native.dart'
    if (dart.library.html) 'package:mywords/util/util_web.dart';


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

  if (platFormIsDesktopWeb()) {
    // desktop web
    double width = getPlatformWebWidth(context);
    adjustedBody = Center(child: SizedBox(width: width, child: body));
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
