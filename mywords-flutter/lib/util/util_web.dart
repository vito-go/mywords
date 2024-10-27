import 'dart:html' as html;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../environment.dart';

// 判断是否手机浏览器
bool _platFormWebIsMobile() {
  if (!kIsWeb) {
    return false;
  }
  final appVersion = html.window.navigator.appVersion;
  final appVersionLower = appVersion.toLowerCase();
  if (appVersionLower.contains("mobile") ||
      appVersionLower.contains("android") ||
      appVersionLower.contains("iphone")) {
    return true;
  }
  return false;
}

// platFormIsDesktopWeb
bool platFormIsDesktopWeb() {
  if (!kIsWeb) {
    return false;
  }
  return !_platFormWebIsMobile();
}

double getPlatformWebWidth(BuildContext context) {
  if (!platFormIsDesktopWeb()) return double.infinity;
  // desktop web
  const noMobileWidthRate = 0.35;
  final webBodyWidthDouble = webBodyWidth.toDouble();
  double mediaWidth = MediaQuery.of(context).size.width;
  double width = mediaWidth * noMobileWidthRate;
  if (width < webBodyWidthDouble) {
    width = webBodyWidthDouble;
  }
  return width;
}
