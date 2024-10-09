import 'dart:async';
import 'dart:convert';
import 'dart:html' show window;

import 'package:dio/dio.dart';
import 'package:mywords/libso/interface.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/libso/types.dart';
import 'package:mywords/widgets/line_chart.dart';

import 'package:mywords/environment.dart';

final Handler handlerImplement = WebHandler();

class WebHandler implements Handler {
  @override
  Future<RespData<void>> addDict(String zipPath) async {
    throw "not support add dict on web platform in this way";
  }

  @override
  Future<RespData<void>> updateFileInfo(FileInfo item) async {
    final result = await call("UpdateFileInfo", [item.toRawJson()]);
    final RespData respData =
        RespData.fromJson(jsonDecode(result), (json) => null);
    return respData;
  }

  @override
  Future<RespData<Article>> articleFromFileInfo(FileInfo fileInfo) async {
    final result = await call("ArticleFromFileInfo", [fileInfo]);

    final RespData<Article> respData =
        RespData.fromJson(jsonDecode(result), (json) => Article.fromJson(json));
    return respData;
  }

  @override
  Future<RespData<void>> delDict(int id) async {
    final result = await call("DelDict", [id]);
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
  Future<RespData<List<DictInfo>>> dictList() async {
    final result = await call("DictList", []);

    final RespData<List<DictInfo>> respData = RespData.fromJson(
        jsonDecode(result),
        (json) => List<DictInfo>.generate(
            json.length, (index) => DictInfo.fromJson(json[index])));
    return respData;
  }

  @override
  Future<String> defaultWordMeaning(String word) async {
    final result = await call("DefaultWordMeaning", [word]);
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
  Future<bool> existInDict(String word) async {
    final result = await call("ExistInDict", [word]);
    return bool.parse(result);
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
  Future<int> getDefaultDictId() async {
    final result = await call("GetDefaultDictId", []);
    return int.parse(result);
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
  Future<String> getUrlByWordForWeb(String hostname, String word) async {
    final result = await call("GetUrlByWordForWeb", [hostname, word]);
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
  Future<RespData<List<String>>> searchByKeyWord(String word) async {
    final result = await call("SearchByKeyWord", [word]);
    final RespData<List<String>> respData = RespData.fromJson(
        jsonDecode(result), (json) => List<String>.from(json));
    return respData;
  }

  @override
  Future<RespData<void>> setDefaultDict(int id) async {
    final result = await call("SetDefaultDict", [id]);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  Future<RespData<void>> shareClosed(int port, int code) async {
    final result = await call("ShareClosed", [port, code]);

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
  Future<RespData<void>> updateDictName(int id, String name) async {
    final result = await call("UpdateDictName", [id, name]);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  Future<RespData<void>> updateKnownWordLevel(
    String word,
    int level,
  ) async {
    final result = await call("UpdateKnownWordLevel", [
      1,
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
    final result = await call("ReparseArticleFileInfo", [id]);
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
  Future<RespData<int>> dbSize() async {
    final resultC = await call("DbSize", []);
    final RespData<int> respData =
        RespData.fromJson(jsonDecode(resultC), (json) {
      return json as int;
    });
    return respData;
  }

  @override
  RespData<int> vacuumDB() {
    call("VacuumDB", []);
    return RespData.dataOK(0);
  }

  @override
  FutureOr<RespData<List<FileInfo>>> getFileInfoListByArchived(
      bool archived) async {
    final result = await call("GetFileInfoListByArchived", [archived]);
    final RespData<List<FileInfo>> respData = RespData.fromJson(
        jsonDecode(result),
        (json) => List<FileInfo>.generate(
            json.length, (index) => FileInfo.fromJson(json[index])));
    return respData;
  }

  @override
  FutureOr<RespData<void>> syncData(
      String ip, int port, int code, int syncKind) async {
    final result = await call("SyncData", [ip, port, code, syncKind]);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) => null);
    return respData;
  }

  @override
  String readMessage() {
    // TODO: implement readMessage with websocket on web Platform
    throw UnimplementedError();
  }

  @override
  FutureOr<List<String>> allWordsByCreateDayAndOrder(
      int createDay, int order) async {
    final result =
        await call("AllWordsByCreateDayAndOrder", [createDay, order]);
    final items = List<String>.from(jsonDecode(result));
    return items;
  }

  @override
  FutureOr<bool> checkDictZipTargetPathExist(String zipPath) async {
    final result = await call("CheckDictZipTargetPathExist", [zipPath]);
    return bool.parse(result);
  }

  @override
  Future<int> webDictRunPort() async {
    final result = await call("WebDictRunPort", []);
    return int.parse(result);
  }

  @override
  RespData<void> restoreFromOldVersionData() {
    call("RestoreFromOldVersionData", []);
    return RespData.dataOK(null);
  }

  @override
  Future<String> goBuildInfoString() async {
    final result = await call("GoBuildInfoString", []);
    return result;
  }

  @override
  void setWebOnlineClose(bool v) {
    call("SetWebOnlineClose", [v]);
  }

  @override
  FutureOr<int> webOnlinePort() async {
    final result = await call("WebOnlinePort", []);
    return int.parse(result);
  }

  @override
  FutureOr<bool> getWebOnlineClose() async {
    final result = await call("GetWebOnlineClose", []);
    return bool.parse(result);
  }

  @override
  FutureOr<RespData<void>> delProxy() async{
    final result = await call("DelProxy", []);

    final RespData respData =
    RespData.fromJson(jsonDecode(result) ?? {}, (json) => null);
    return respData;
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
