import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'dart:io';

String formatTime(DateTime now) {
  String month = now.month < 10 ? "0${now.month}" : "${now.month}";
  String day = now.day < 10 ? "0${now.day}" : "${now.day}";
  String hour = now.hour < 10 ? "0${now.hour}" : "${now.hour}";
  String minute = now.minute < 10 ? "0${now.minute}" : "${now.minute}";
  String second = now.second < 10 ? "0${now.second}" : "${now.second}";
  return "${now.year}-$month-$day $hour:$minute:$second";
}

myToast(BuildContext context, dynamic msg) {
   myPrint(msg, skip: 2);

  if (!context.mounted) return;
  showToast(
    "$msg",
    context: context,
    animation: StyledToastAnimation.fade,
    reverseAnimation: StyledToastAnimation.fade,
    position: StyledToastPosition.center,
    // curve: Curves.linear,
    // reverseCurve: Curves.linear,
  );
}

myPrint(dynamic msg,
    {List<dynamic>? args, String level = 'INFO', int skip = 1}) {
  if (kIsWeb) {
    skip++;
  }
  //  根据环境进行打印输出
  if (kDebugMode) {
    var traceString = StackTrace.current.toString().split("\n")[skip];
    String arg = "";

    if (args != null) {
      arg = "{";
      for (var i = 0; i < args.length; i++) {
        if (i % 2 == 0) {
          arg += '"${args[i]}": ';
        } else {
          if (i == args.length - 1) {
            arg += '${args[i]}';
          } else {
            arg += '${args[i]}, ';
          }
        }
      }
      arg += "}";
    }

    print("[$level] ${DateTime.now()} $traceString $msg $arg");
  }
}

bool platFormIsMobile() {
  // if (kIsWeb) {
  //   final ua = window.navigator.userAgent.toLowerCase();
  //   if (ua.contains("android") || ua.contains("ios")) {
  //     return true;
  //   }
  //   return false;
  // }
  if (Platform.isAndroid || Platform.isIOS) {
    return true;
  }
  return false;
}

copyToClipBoard(BuildContext context, String content) {
  Clipboard.setData(ClipboardData(text: content));
  if (!platFormIsMobile()) {
    myPrint(content);
    myToast(context, "复制成功");
  }
}
