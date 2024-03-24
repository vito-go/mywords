import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mywords/libso/interface.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/libso/types.dart';
import 'package:mywords/widgets/line_chart.dart';

import 'package:mywords/environment.dart';

import 'package:mywords/util/local_cache.dart';

final Interface handler = HTTPHandler();

class HTTPHandler implements Interface {
  @override
  Future<RespData<void>> addDict(String dataDir) async {
    throw "not support add dict on web platform in this way";
  }

  @override
  Future<RespData<Map<int, List<String>>>> allKnownWordMap() async {
    final result = await call("AllKnownWordMap", []);
    final RespData<Map<int, List<String>>> respData =
        RespData.fromJson(jsonDecode(result), (json) {
      Map<int, List<String>> result = {};
      final data = json as Map<String, dynamic>;
      for (var entry in data.entries) {
        final List<dynamic> words = entry.value;
        result[int.parse(entry.key)] = List<String>.generate(
            words.length, (index) => (words[index].toString()));
      }
      return result;
    });
    return respData;
  }

  @override
  Future<RespData<void>> archiveGobFile(String fileName) async {
    final result = await call("ArchiveGobFile", [fileName]);
    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);
    return respData;
  }

  @override
  Future<RespData<String>> backUpData(String zipName, String dataDirPath) {
    // TODO: implement backUpData
    throw UnimplementedError();
  }

  @override
  Future<RespData<Article>> articleFromGobFile(String fileName) async {
    final result = await call("ArticleFromGobFile", [fileName]);

    final RespData<Article> respData =
        RespData.fromJson(jsonDecode(result), (json) => Article.fromJson(json));
    return respData;
  }

  @override
  Future<RespData<void>> delDict(String basePath) async {
    LocalCache.defaultDictBasePath = null;
    final result = await call("DelDict", [basePath]);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  Future<RespData<void>> deleteGobFile(String fileName) async {
    final result = await call("DeleteGobFile", [fileName]);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  Future<RespData<List>> dictList() async {
    final result = await call("DictList", []);

    final RespData<List<dynamic>> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as List<dynamic>);
    return respData;
  }

  @override
  Future<String> dictWordQuery(String word) async {
    final result = await call("DictWordQuery", [word]);
    final respData =
        RespData.fromJson(jsonDecode(result), (json) => json.toString());
    String define = respData.data ?? '';
    return define;
  }

  @override
  Future<String> dictWordQueryLink(String word) async {
    final result = await call("DictWordQueryLink", [word]);

    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    final data = respData.data ?? '';
    if (data != "") {
      return data;
    }
    return word;
  }

  @override
  Future<String> finalHtmlBasePathWithOutHtml(String word) async {
    final result = await call("FinalHtmlBasePathWithOutHtml", [word]);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data ?? "";
  }

  @override
  Future<RespData<List<FileInfo>>> getArchivedFileInfoList() async {
    final result = await call("GetArchivedFileInfoList", []);

    final RespData<List<FileInfo>> respData = RespData.fromJson(
        jsonDecode(result),
        (json) => List<FileInfo>.generate(
            json.length, (index) => FileInfo.fromJson(json[index])));
    return respData;
  }

  @override
  Future<RespData<ChartLineData>> getChartData() async {
    final result = await call("GetChartData", []);

    final RespData<ChartLineData> respData = RespData.fromJson(
        jsonDecode(result), (json) => ChartLineData.fromJson(json));
    return respData;
  }

  @override
  Future<RespData<ChartLineData>> getChartDataAccumulate() async {
    final result = await call("GetChartDataAccumulate", []);

    final RespData<ChartLineData> respData = RespData.fromJson(
        jsonDecode(result), (json) => ChartLineData.fromJson(json));
    return respData;
  }

  @override
  Future<RespData<String>> getDefaultDict() async {
    final result = await call("GetDefaultDict", []);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData;
  }

  @override
  Future<RespData<String>> getHTMLRenderContentByWord(String word) async {
    final result = await call("GetHTMLRenderContentByWord", [word]);

    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData;
  }

  @override
  Future<RespData<Map<String, dynamic>>>
      getToadyChartDateLevelCountMap() async {
    final result = await call("GetToadyChartDateLevelCountMap", []);
    final RespData<Map<String, dynamic>> respData = RespData.fromJson(
        jsonDecode(result), (json) => json as Map<String, dynamic>);
    return respData;
  }

  @override
  Future<String> getUrlByWord(String word) async {
    final result = await call("GetUrlByWord", [word]);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data ?? '';
  }

  @override
  Future<RespData<void>> parseAndSaveArticleFromSourceUrl(String www) async {
    final result = await call("ParseAndSaveArticleFromSourceUrl", [www]);
    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);

    return respData;
  }

  @override
  Future<RespData<Article>> parseAndSaveArticleFromSourceUrlAndContent(
      String www, String htmlContent, int lastModified) async {
    final result = await call("ParseAndSaveArticleFromSourceUrlAndContent",
        [www, htmlContent, lastModified]);

    final RespData<Article> respData = RespData<Article>.fromJson(
        jsonDecode(result), (json) => Article.fromJson(json));

    return respData;
  }

  @override
  Future<String> parseVersion() async {
    final result = await call("ParseVersion", []);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data!;
  }

  @override
  void println(String msg) {
    // TODO: implement println
    // console.log
  }

  // Deprecated please use queryWordsLevel
  @override
  Future<int> queryWordLevel(String word) async {
    final result = await call("QueryWordLevel", [word]);
    final RespData<int> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as int);
    final int l = respData.data ?? 0;
    return l;
  }

  @override
  Future<RespData<void>> restoreFromBackUpData(
      bool syncKnownWords,
      String zipPath,
      bool syncToadyWordCount,
      bool syncByRemoteArchived) async {
    final result = await call("RestoreFromBackUpData",
        [zipPath, syncToadyWordCount, syncByRemoteArchived]);

    final respData = RespData.fromJson(jsonDecode(result), (json) => null);

    return respData;
  }

  @override
  Future<RespData<void>> restoreFromShareServer(
      String ip,
      int port,
      int code,
      bool syncKnownWords,
      String tempDir,
      bool syncToadyWordCount,
      bool syncByRemoteArchived) async {
    final result = await call("RestoreFromShareServer", [
      ip,
      port,
      code,
      syncKnownWords,
      tempDir,
      syncToadyWordCount,
      syncByRemoteArchived
    ]);

    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);

    return respData;
  }

  @override
  Future<RespData<List<String>>> searchByKeyWord(String word) async {
    final result = await call("SearchByKeyWord", [word]);
    final RespData<List<String>> respData = RespData.fromJson(
        jsonDecode(result), (json) => List<String>.from(json));
    return respData;
  }

  @override
  Future<RespData<List<String>>> searchByKeyWordWithDefault(String word) async {
    final result = await call("SearchByKeyWordWithDefault", [word]);

    final RespData<List<String>> respData = RespData.fromJson(
        jsonDecode(result), (json) => List<String>.from(json));
    return respData;
  }

  @override
  Future<RespData<void>> setDefaultDict(String basePath) async {
    LocalCache.defaultDictBasePath = null;
    final result = await call("SetDefaultDict", [basePath]);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  void setLogUrl(String logUrl, String logNonce) {
    // TODO: implement setLogUrl
    // not supported web
  }

  @override
  Future<RespData<void>> shareClosed() async {
    final result = await call("ShareClosed", []);

    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);
    return respData;
  }

  @override
  Future<RespData<void>> shareOpen(int port, int code) async {
    final result = await call("ShareOpen", [port, code]);
    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);
    return respData;
  }

  @override
  Future<RespData<List<FileInfo>>> showFileInfoList() async {
    final result = await call("ShowFileInfoList", []);
    final RespData<List<FileInfo>> respData = RespData.fromJson(
        jsonDecode(result),
        (json) => List<FileInfo>.generate(
            json.length, (index) => FileInfo.fromJson(json[index])));
    return respData;
  }

  @override
  Future<RespData<Map<int, List<String>>>> todayKnownWordMap() async {
    final result = await call("TodayKnownWordMap", []);

    final RespData<Map<int, List<String>>> respData =
        RespData.fromJson(jsonDecode(result), (json) {
      Map<int, List<String>> result = {};
      final data = json as Map<String, dynamic>;
      for (var entry in data.entries) {
        final List<dynamic> words = entry.value;
        result[int.parse(entry.key)] = List<String>.generate(
            words.length, (index) => (words[index].toString()));
      }
      return result;
    });

    return respData;
  }

  @override
  Future<RespData<void>> unArchiveGobFile(String fileName) async {
    final result = await call("UnArchiveGobFile", [fileName]);

    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);
    return respData;
  }

  @override
  Future<RespData<void>> updateDictName(String dataDir, String name) {
    // TODO: implement updateDictName
    throw UnimplementedError();
  }

  @override
  Future<RespData<void>> updateKnownWords(int level, String word) async {
    final result = await call("UpdateKnownWords", [
      level,
      [word]
    ]);

    final respData = RespData.fromJson(jsonDecode(result), (json) => null);

    return respData;
  }

  @override
  Future<void> initLib() async {
    // TODO: implement initLib
    // there is nothing to do
    return;
  }

  @override
  Future<RespData<Map<String, dynamic>>> levelDistribute(
      List<String> words) async {
    final result = await call("LevelDistribute", [words]);

    final respData = RespData.fromJson(
        jsonDecode(result), (json) => json as Map<String, dynamic>);

    return respData;
  }

  @override
  Future<Map<String, dynamic>> knownWordsCountMap() async {
    final result = await call("KnownWordsCountMap", []);

    final RespData<Map<String, dynamic>> respData = RespData.fromJson(
        jsonDecode(result) ?? {}, (json) => json as Map<String, dynamic>);

    return respData.data ?? {};
  }

  @override
  Future<RespData<void>> parseAndSaveArticleFromFile(String path) async {
    final result = await call("ParseAndSaveArticleFromFile", [path]);

    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);

    return respData;
  }

  @override
  Future<RespData<void>> setProxyUrl(String netProxy) async {
    final result = await call("SetProxyUrl", [netProxy]);

    final RespData respData =
        RespData.fromJson(jsonDecode(result) ?? {}, (json) => null);
    return respData;
  }

  @override
  FutureOr<Map<String, int>> queryWordsLevel(List<String> words) async {
    final result = await call("QueryWordsLevel", [words]);
    final respData = RespData.fromJson(jsonDecode(result), (json) {
      return (json as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int));
    });
    return respData.data ?? {};
  }

  @override
  FutureOr<String> getFileNameBySourceUrl(String sourceUrl) async {
    final result = await call("GetFileNameBySourceUrl", [sourceUrl]);
    final respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data ?? "";
  }

  @override
  FutureOr<List<String>?> getIPv4s() async {
    final result = await call("GetIPv4s", []);
    final respData = RespData.fromJson(jsonDecode(result), (json) {
      return (json as List<dynamic>).map((e) => e as String).toList();
    });
    return respData.data;
  }

  @override
  FutureOr<String> proxyURL() async {
    final result = await call("ProxyURL", []);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data??"";
  }
}

Future<String> call(String funcName, List<dynamic> args) async {
  final dio = Dio();
  final www = "$debugHostOrigin/call/$funcName";
  try {
    final Response<String> response = await dio.post(
      www,
      data: jsonEncode(args),
      options: Options(
          responseType: ResponseType.plain,
          validateStatus: (_) {
            return true;
          }),
    );
    if (response.statusCode != 200) {
      return jsonEncode(
          {"code": response.statusCode ?? -1, "message": response.data ?? ""});
    }
    return response.data ?? "{}";
  } catch (e) {
    return jsonEncode({
      "code": -1,
      "message": e.toString(),
    });
  }
}
