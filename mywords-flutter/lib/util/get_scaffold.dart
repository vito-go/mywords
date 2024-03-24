import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/environment.dart';

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
  final webBodyWidthDouble = webBodyWidth.toDouble();
  double mediaWidth = MediaQuery.of(context).size.width;

  if (platFormIsMobile()) {
    adjustedBody = body;
  } else if (webBodyWidthDouble <= 0) {
    adjustedBody = body;
  } else if (mediaWidth > webBodyWidthDouble) {
    double width = double.infinity;
    width = mediaWidth * noMobileWidthRate;
    if (width < webBodyWidthDouble) {
      width = webBodyWidthDouble;
    }
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
