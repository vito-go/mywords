import 'package:mywords/libso/handler.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Global {
  // 需要在main函数中初始化，且在handler.initLib()之后。 如果有更新。本地缓存也需要更新。
  static Map<String, int> allKnownWordsMap = {}; //TODO: 本地缓存 梳理下都有哪些地方会更新这个数据
  static String parseVersion = '';
  static int webDictRunPort = 0;
  static int webOnlinePort = 0;
  static String _version = "";
  static String goBuildInfoString = "";
  static  String get version => _version;
  static const String email="vitogo2024@gmail.com";

  static Map<int, int> levelDistribute(List<String> words) {
    final Map<int, int> resultMap = {};
    for (final word in words) {
      final level = allKnownWordsMap[word] ?? 0;
      resultMap[level] = (resultMap[level] ?? 0) + 1;
    }
    return resultMap;
  }

  static Future<void> init() async {
    handler.getDefaultDictId();
    parseVersion = await handler.parseVersion();
    goBuildInfoString = await handler.goBuildInfoString();
    final respData = await handler.allKnownWordsMap();
    if (respData.code != 0) {
      throw Exception("allKnownWordsMap error: ${respData.message}");
    }
    allKnownWordsMap = respData.data ?? {};
    webDictRunPort = await handler.webDictRunPort();
    webOnlinePort = await handler.webOnlinePort();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _version= packageInfo.version;
  }
}
