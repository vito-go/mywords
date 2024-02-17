import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
 bool platFormIsMobile() {
  if (kIsWeb) {
    return false;
  }
  if (Platform.isAndroid || Platform.isIOS) {
    return true;
  }
  return false;
}

Widget getScaffold(BuildContext context,
    {required Widget body,
    PreferredSizeWidget? appBar,
    Widget? drawer,
    double noMobileWidthRate = 0.35,
     }) {
  if (platFormIsMobile()) {
    return Scaffold(
      body: body,
      appBar: appBar,
      drawer: drawer,
    );
  }

  double mediaWidth = MediaQuery.of(context).size.width;
  double width = double.infinity;
  if (mediaWidth > 500) {
    width = mediaWidth * noMobileWidthRate;
    if (width < 500) {
      width = 500;
    }
  }
  return Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: body,
      ),
    ),
    appBar: appBar,
    drawer: drawer,
  );
}
