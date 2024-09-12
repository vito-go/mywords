import 'dart:async';
import 'dart:convert';
import 'dart:html' show window;

import 'package:dio/dio.dart';
import 'package:mywords/libso/interface.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/libso/types.dart';
import 'package:mywords/widgets/line_chart.dart';

import 'package:mywords/environment.dart';


import 'package:url_launcher/url_launcher_string.dart';

import '../common/global.dart';

final Handler handlerImplement = WebHandler();

class WebHandler implements Handler {
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
  Future<RespData<void>> updateFileInfo(FileInfo item) async {
    final result = await call("ArchiveGobFile", [item.toRawJson()]);
    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);
    return respData;
  }

  @override
  Future<RespData<String>> backUpData(
      String zipName, String dataDirPath) async {
    final www = "$debugHostOrigin/_downloadBackUpdate?name=$zipName";
    launchUrlString(www);
    return RespData.dataOK("");
  }

  @override
  Future<RespData<Article>> articleFromFileInfo(FileInfo fileInfo) async {
    final result = await call("ArticleFromFileInfo", [fileInfo]);

    final RespData<Article> respData =
        RespData.fromJson(jsonDecode(result), (json) => Article.fromJson(json));
    return respData;
  }

  @override
  Future<RespData<void>> delDict(String basePath) async {
    Global.defaultDictBasePath = '';
    final result = await call("DelDict", [basePath]);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  Future<RespData<void>> deleteGobFile(int id) async {
    final result = await call("DeleteGobFile", [id]);
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
  Future<String> getUrlByWord(String hostname, String word) async {
    final result = await call("GetUrlByWord", [hostname, word]);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data ?? '';
  }

  @override
  Future<String> parseVersion() async {
    final result = await call("ParseVersion", []);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data!;
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
    Global.defaultDictBasePath = '';
    final result = await call("SetDefaultDict", [basePath]);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
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
  Future<RespData<void>> updateDictName(String dataDir, String name) {
    // TODO: implement updateDictName
    throw UnimplementedError();
  }

  @override
  Future<RespData<void>> updateKnownWordLevel(
    String word,
    int level,
  ) async {
    final result = await call("UpdateKnownWordLevel", [
      word,
      level,
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
  Future<Map<String, dynamic>> knownWordsCountMap() async {
    final result = await call("KnownWordsCountMap", []);

    final RespData<Map<String, dynamic>> respData = RespData.fromJson(
        jsonDecode(result) ?? {}, (json) => json as Map<String, dynamic>);

    return respData.data ?? {};
  }

  @override
  Future<RespData<void>> setProxyUrl(String netProxy) async {
    final result = await call("SetProxyUrl", [netProxy]);

    final RespData respData =
        RespData.fromJson(jsonDecode(result) ?? {}, (json) => null);
    return respData;
  }


  @override
  FutureOr<FileInfo?> getFileInfoBySourceURL(String sourceUrl) async {
    final result = await call("GetFileInfoBySourceURL", [sourceUrl]);
    final respData = RespData.fromJson(
        jsonDecode(result), (json) => FileInfo.fromJson(json));
    return respData.data;
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
    return respData.data ?? "";
  }

  @override
  String getHostName() {
    return window.location.hostname ?? '';
  }

  @override
  FutureOr<ShareInfo> getShareInfo() async {
    final result = await call("GetShareInfo", []);
    final RespData<ShareInfo> respData = RespData.fromJson(
        jsonDecode(result), (json) => ShareInfo.fromJson(json));
    return respData.data!;
  }

  @override
  FutureOr<RespData<Article>> newArticleFileInfoBySourceURL(String www) async {
    final result = await call("NewArticleFileInfoBySourceURL", [www]);
    final RespData<Article> respData =
        RespData.fromJson(jsonDecode(result), (json) => Article.fromJson(json));
    return respData;
  }

  @override
  FutureOr<RespData<Article>> renewArticleFileInfo(int id) async {
    final result = await call("RenewArticleFileInfo", [id]);
    final RespData<Article> respData =
        RespData.fromJson(jsonDecode(result), (json) => Article.fromJson(json));
    return respData;
  }

  @override
  FutureOr<RespData<Article>> reparseArticleFileInfo(int id) async {
    final result = await call("RenewArticleFileInfo", [id]);
    final RespData<Article> respData =
        RespData.fromJson(jsonDecode(result), (json) => Article.fromJson(json));
    return respData;
  }

  @override
  FutureOr<RespData<Map<String, int>>> allKnownWordsMap() async {
    final resultC = await call("AllKnownWordsMap", []);
    final respData = RespData.fromJson(jsonDecode(resultC), (json) {
      return (json as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int));
    });
    return respData;
  }

  @override
  RespData<int> dbSize() {
    // TODO: implement dbSize
    throw UnimplementedError();
  }

  @override
  RespData<int> vacuumDB() {
    // TODO: implement vacuumDB
    throw UnimplementedError();
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
