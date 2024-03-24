import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

String? getHomeDir() {
  String? homeDirectory;
  if (Platform.isWindows) {
    homeDirectory = Platform.environment['USERPROFILE'] ?? '';
    if (homeDirectory == "") {
      homeDirectory = Platform.environment['HOME'] ?? '';
    }
  } else if (Platform.isLinux || Platform.isMacOS) {
    homeDirectory = Platform.environment['HOME'] ?? '';
  }
  return homeDirectory;
}

String? getDefaultDownloadDir() {
  if (kIsWeb)return null;
  if (Platform.isAndroid) {
    return "/storage/emulated/0/Download/";
  }
  // 获取可执行文件的路径
  String homeDirectory = getHomeDir() ?? '';
  if (homeDirectory != "") {
    return path.join(homeDirectory, "Downloads");
  }
  return null;
}
