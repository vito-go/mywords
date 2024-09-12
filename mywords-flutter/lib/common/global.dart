import 'package:mywords/libso/handler.dart';

class Global {
  // 需要在main函数中初始化，且在handler.initLib()之后。 如果有更新。本地缓存也需要更新。
  static Map<String, int> allKnownWordsMap = {}; //TODO: 本地缓存 梳理下都有哪些地方会更新这个数据
  static String parseVersion = '';
  static String defaultDictBasePath = '';

  static Map<int, int> levelDistribute(List<String> words) {
    final Map<int, int> resultMap = {};
    for (final word in words) {
      final level = allKnownWordsMap[word]??0;

      resultMap[level] = (resultMap[level] ?? 0) + 1;
    }
    return resultMap;
  }

  static Future<void> init() async {
    handler.getDefaultDict();
    defaultDictBasePath = (await handler.getDefaultDict()).data ?? '';
    parseVersion = await handler.parseVersion();
    final respData = await handler.allKnownWordsMap();
    if (respData.code != 0) {
      throw Exception("allKnownWordsMap error: ${respData.message}");
    }
    allKnownWordsMap = respData.data ?? {};
  }
}
