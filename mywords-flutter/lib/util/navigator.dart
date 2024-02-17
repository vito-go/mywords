import 'package:flutter/material.dart';

Future<dynamic> pushTo(BuildContext context, Widget w) {
  return Navigator.push(context,
      MaterialPageRoute(builder: (BuildContext context) {
    return w;
  }));
}
