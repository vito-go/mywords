import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'package:ffi/ffi.dart';

import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/funcs.dart';

import 'package:mywords/util/util.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initLib() async {
  final dir = await getApplicationSupportDirectory();
  myPrint("ApplicationSupportDirectory: $dir");
  final c = dir.path.toNativeUtf8();
  final proxyUrl = prefs.netProxy.toNativeUtf8();
  myPrint(prefs.netProxy);
  init(c, proxyUrl);
  malloc.free(c);
  malloc.free(proxyUrl);
}
final DynamicLibrary nativeAddLib = getLibGo();

DynamicLibrary getLibGo() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libgo.so');
  }
  if (Platform.isLinux) {
    return DynamicLibrary.open(path.join(
        kDebugMode ? "" : path.dirname(Platform.resolvedExecutable),
        "libs/libgo_linux.so"));
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open(path.join(
        kDebugMode ? "" : path.dirname(Platform.resolvedExecutable),
        "libs/libgo_windows.so"));
  }
  throw "DynamicLibrary Platform: ${Platform.operatingSystem}  implement me";
}
