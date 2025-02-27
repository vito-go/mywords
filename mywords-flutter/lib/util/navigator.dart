import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<dynamic> pushTo(BuildContext context, Widget w) {
  final targetPlatform = Theme.of(context).platform;
  if (targetPlatform == TargetPlatform.iOS ||
      targetPlatform == TargetPlatform.macOS) {
    return Navigator.push(context,
        CupertinoPageRoute(builder: (BuildContext context) {
      return w;
    }));
  }
  return Navigator.push(context,
      MaterialPageRoute(builder: (BuildContext context) {
    return w;
  }));
}
