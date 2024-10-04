import 'package:mywords/libso/handler.dart';

class Global {
  // 需要在main函数中初始化，且在handler.initLib()之后。 如果有更新。本地缓存也需要更新。
  static Map<String, int> allKnownWordsMap = {}; //TODO: 本地缓存 梳理下都有哪些地方会更新这个数据
  static String parseVersion = '';
   static int webDictRunPort = 0;
  static const version = "3.0.0";
  static String goBuildInfoString = "";

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
    webDictRunPort = await handler.webDictRunPort();
    allKnownWordsMap = respData.data ?? {};
  }
}
