import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/widgets/line_chart.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mywords/util/util.dart';
import 'types.dart';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:mywords/libso/interface.dart';

import 'package:flutter/foundation.dart';

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

final Handler handlerImplement = NativeHandler();

class NativeHandler implements Handler {
  @override
  void initLib() async {
    final dir = await getApplicationSupportDirectory();
    myPrint("ApplicationSupportDirectory: $dir");
    final c = dir.path.toNativeUtf8();
    init(c);
    malloc.free(c);
  }

// func Init(dataDir *C.char )
  final init = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
      void Function(Pointer<Utf8>)>('Init');

  @override
  String readMessage() {
    final resultC = _readMessage();
    final result = resultC.toDartString();
    malloc.free(resultC);
    return result;
  }

  final _readMessage = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('ReadMessage');

//func UpdateKnownWords(level int, c *C.char) *C.char
  final UpdateKnownWordLevel = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64, Pointer<Utf8>, Int64),
      Pointer<Utf8> Function(int, Pointer<Utf8>, int)>('UpdateKnownWordLevel');

//func UpdateKnownWords(level int, c *C.char) *C.char
  final NewArticleFileInfoBySourceURL = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('NewArticleFileInfoBySourceURL');

//func UpdateKnownWords(level int, c *C.char) *C.char
  final RenewArticleFileInfo = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64),
      Pointer<Utf8> Function(int)>('RenewArticleFileInfo');

  final AllKnownWordsMap = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('AllKnownWordsMap');

//func UpdateKnownWords(level int, c *C.char) *C.char
  final ReparseArticleFileInfo = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64),
      Pointer<Utf8> Function(int)>('ReparseArticleFileInfo');

  final _deleteGobFile = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64),
      Pointer<Utf8> Function(int)>('DeleteGobFile');

  @override
  RespData<void> deleteGobFile(int id) {
    // // func ShowGobContentByLevel(fileName *C.char, level int) *C.char
    final resultC = _deleteGobFile(id);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(resultC);
    return respData;
  }

// func ArchiveGobFile(fileName *C.char) *C.char
  final UpdateFileInfo = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('UpdateFileInfo');

  @override
  RespData<void> updateFileInfo(FileInfo item) {
    // // func ShowGobContentByLevel(fileName *C.char, level int) *C.char
    final c = item.toRawJson().toNativeUtf8();
    final resultC = UpdateFileInfo(c);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    return respData;
  }

  final GetFileInfoListByArchived = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Bool),
      Pointer<Utf8> Function(bool)>('GetFileInfoListByArchived');

  @override
  RespData<List<FileInfo>> getFileInfoListByArchived(bool archived) {
    final c = GetFileInfoListByArchived(archived);
    final RespData<List<FileInfo>> respData = RespData.fromJson(
        jsonDecode(c.toDartString()),
        (json) => List<FileInfo>.generate(
            json.length, (index) => FileInfo.fromJson(json[index])));
    malloc.free(c);
    return respData;
  }

// func ShowGobContentByLevel(fileName *C.char, level int) *C.char
  final ArticleFromFileInfo = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('ArticleFromFileInfo');

  @override
  RespData<Article> articleFromFileInfo(FileInfo fileInfo) {
    // // func ShowGobContentByLevel(fileName *C.char, level int) *C.char
    final info = fileInfo.toRawJson().toNativeUtf8();
    final c = ArticleFromFileInfo(info);
    final RespData<Article> respData = RespData.fromJson(
        jsonDecode(c.toDartString()), (json) => Article.fromJson(json));
    malloc.free(info);
    malloc.free(c);
    return respData;
  }

// func SetProxyUrl(netProxy *C.char) *C.char {
  final _setProxyUrl = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('SetProxyUrl');

  // DelProxy
  final _delProxy = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('DelProxy');

// Translate
  final _translate = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('Translate');

  @override
  RespData<void> setProxyUrl(String netProxy) {
    final netProxyC = netProxy.toNativeUtf8();
    final resultC = _setProxyUrl(netProxyC);
    malloc.free(netProxyC);
    final RespData respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()) ?? {}, (json) => null);
    malloc.free(resultC);
    return respData;
  }

// func DictWordQuery(wordC *C.char) *C.char //查不到就是空
  final DefaultWordMeaning = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('DefaultWordMeaning');

  @override
  String defaultWordMeaning(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = DefaultWordMeaning(wordC);
    final respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()), (json) => json.toString());
    malloc.free(wordC);
    malloc.free(resultC);
    String define = respData.data ?? '';
    return define;
  }

// func DictWordQuery(wordC *C.char) *C.char //查不到就是空
  final _dictWordQueryLink = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('DictWordQueryLink');

  @override
  String dictWordQueryLink(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = _dictWordQueryLink(wordC);
    malloc.free(wordC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    final data = respData.data ?? '';
    if (data != "") {
      return data;
    }
    return word;
  }

// setXpathExpr . usually for debug
  final setXpathExpr = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('SetXpathExpr');

// func KnownWordsCountMap() *C.char  map[server.WordKnownLevel]int
  final _knownWordsCountMap = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(), Pointer<Utf8> Function()>('KnownWordsCountMap');

  @override
  Map<String, dynamic> knownWordsCountMap() {
    final resultC = _knownWordsCountMap();
    final RespData<Map<String, dynamic>> respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()) ?? {},
        (json) => json as Map<String, dynamic>);
    malloc.free(resultC);
    return respData.data ?? {};
  }

  final _parseVersion = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('ParseVersion');

  @override
  String parseVersion() {
    final resultC = _parseVersion();
    final RespData<String> respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()), (json) => json as String);
    malloc.free(resultC);
    return respData.data!;
  }

// func ShareOpen(port int, code int64) *C.char  port tokenCode
  final _shareOpen = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64, Int64),
      Pointer<Utf8> Function(int, int)>('ShareOpen');

// func GetChartData() *C.char {
  final _getChartData = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetChartData');

  final _getChartDataAccumulate = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetChartDataAccumulate');

// func GetToadyChartDateLevelCountMap() *C.char
  final _getToadyChartDateLevelCountMap = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetToadyChartDateLevelCountMap');

// func ShareClosed( ) *C.char
  final _shareClosed = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64, Int64),
      Pointer<Utf8> Function(int, int)>('ShareClosed');

  @override
  RespData<void> shareClosed(int port, int code) {
    final resultC = _shareClosed(port, code);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(resultC);
    return respData;
  }

  @override
  RespData<void> shareOpen(int port, int code) {
    final resultC = _shareOpen(port, code);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(resultC);
    return respData;
  }

  @override
  RespData<ChartLineData> getChartData() {
    final resultC = _getChartData();
    final RespData<ChartLineData> respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()),
        (json) => ChartLineData.fromJson(json));
    malloc.free(resultC);
    return respData;
  }

  @override
  RespData<ChartLineData> getChartDataAccumulate() {
    final resultC = _getChartDataAccumulate();
    final RespData<ChartLineData> respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()),
        (json) => ChartLineData.fromJson(json));
    malloc.free(resultC);
    return respData;
  }

// compute must be top level function
  @override
  RespData<Map<String, dynamic>> getToadyChartDateLevelCountMap() {
    final resultC = _getToadyChartDateLevelCountMap();
    final RespData<Map<String, dynamic>> respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()),
        (json) => json as Map<String, dynamic>);
    malloc.free(resultC);
    return respData;
  }

  @override
  RespData<void> updateKnownWordLevel(String word, int level) {
    final wordC = word.toNativeUtf8();
    // 0 for client version, 1 for web version
    final resultC = UpdateKnownWordLevel(0, wordC, level);
    final respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(wordC);
    malloc.free(resultC);
    return respData;
  }

// func QueryWordLevel(wordC *C.char) *C.char
  final GetUrlByWordForWeb = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>),
      Pointer<Utf8> Function(
          Pointer<Utf8>, Pointer<Utf8>)>('GetUrlByWordForWeb');

// getUrlByWord 返回防止携带word参数
  @override
  String getUrlByWordForWeb(String hostName, String word) {
    final wordC = word.toNativeUtf8();
    final hostNameC = hostName.toNativeUtf8();
    final resultC = GetUrlByWordForWeb(hostNameC, wordC);
    malloc.free(hostNameC);
    malloc.free(wordC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data ?? '';
  }

// func   UpdateDictName(dataDirC, nameC *C.char) *C.char {
  final _updateDictName = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64, Pointer<Utf8>),
      Pointer<Utf8> Function(int, Pointer<Utf8>)>('UpdateDictName');

  @override
  RespData<void> updateDictName(int id, String name) {
    final nameC = name.toNativeUtf8();
    final resultC = _updateDictName(id, nameC);
    malloc.free(nameC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

// func SetDefaultDict(dataDirC *C.char) *C.char {
  final _setDefaultDict = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64),
      Pointer<Utf8> Function(int)>('SetDefaultDict');

// VacuumDB
  final VacuumDB = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('VacuumDB');

// func DBSize() *C.char
  final DBSize = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('DBSize');

  // WebDictRunPort
  final WebDictRunPort = nativeAddLib
      .lookupFunction<Int64 Function(), int Function()>('WebDictRunPort');

  @override
  RespData<int> vacuumDB() {
    final resultC = VacuumDB();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<int> respData =
        RespData.fromJson(jsonDecode(result), (json) {
      return json as int;
    });
    return respData;
  }

  //  DBSize
  @override
  RespData<int> dbSize() {
    final resultC = DBSize();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<int> respData =
        RespData.fromJson(jsonDecode(result), (json) {
      return json as int;
    });
    return respData;
  }

  @override
  RespData<void> setDefaultDict(int id) {
    final resultC = _setDefaultDict(id);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

// func DictList() *C.char {
  final _dictList = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('DictList');

  @override
  RespData<List<DictInfo>> dictList() {
    final resultC = _dictList();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<List<DictInfo>> respData = RespData.fromJson(
        jsonDecode(result),
        (json) => List<DictInfo>.generate(
            json.length, (index) => DictInfo.fromJson(json[index])));
    return respData;
  }

// func AddDict(dataDirC *C.char) *C.char {

  final _addDict = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('AddDict');

  @override
  RespData<void> addDict(String zipPath) {
    final zipPathC = zipPath.toNativeUtf8();
    final resultC = _addDict(zipPathC);
    malloc.free(zipPathC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

// func DelDict(basePath *C.char) *C.char {
  final _delDict = nativeAddLib.lookupFunction<Pointer<Utf8> Function(Int64),
      Pointer<Utf8> Function(int)>('DelDict');

  @override
  RespData<void> delDict(int id) {
    final resultC = _delDict(id);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

// func SearchByKeyWord(keyWordC *C.char) *C.char {}
  final _searchByKeyWord = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('SearchByKeyWord');

  @override
  RespData<List<String>> searchByKeyWord(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = _searchByKeyWord(wordC);
    malloc.free(wordC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<List<String>> respData = RespData.fromJson(
        jsonDecode(result), (json) => List<String>.from(json));
    return respData;
  }

  final _getDefaultDictId = nativeAddLib
      .lookupFunction<Int64 Function(), int Function()>('GetDefaultDictId');

  @override
  int getDefaultDictId() {
    return _getDefaultDictId();
  }

  final _getHTMLRenderContentByWord = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('GetHTMLRenderContentByWord');

  final GetFileInfoBySourceURL = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('GetFileInfoBySourceURL');

  @override
  RespData<String> getHTMLRenderContentByWord(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = _getHTMLRenderContentByWord(wordC);
    malloc.free(wordC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData;
  }

  @override
  FileInfo? getFileInfoBySourceURL(String sourceURL) {
    final sourceURLC = sourceURL.toNativeUtf8();
    final resultC = GetFileInfoBySourceURL(sourceURLC);
    malloc.free(sourceURLC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<FileInfo> respData = RespData.fromJson(
        jsonDecode(result), (json) => FileInfo.fromJson(json));
    return respData.data;
  }

  final _fixMyKnownWords = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('FixMyKnownWords');

  RespData<void> fixMyKnownWords() {
    final resultC = _fixMyKnownWords();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  final ExistInDict = nativeAddLib.lookupFunction<Bool Function(Pointer<Utf8>),
      bool Function(Pointer<Utf8>)>('ExistInDict');

  @override
  bool existInDict(String word) {
    final wordC = word.toNativeUtf8();
    final result = ExistInDict(wordC);
    return result;
  }

  @override
  FutureOr<List<String>?> getIPv4s() async {
    final networks =
        await NetworkInterface.list(type: InternetAddressType.IPv4);
    if (networks.isEmpty) [];
    List<String> ips = [];
    for (var i in networks) {
      for (var s in i.addresses) {
        ips.add(s.address);
      }
    }
    ips.sort((a, b) => a.length.compareTo(b.length));
    return ips;
  }

  final _proxyURL = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('ProxyURL');

  @override
  String proxyURL() {
    final resultC = _proxyURL();
    final RespData<String> respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()), (json) => json as String);
    malloc.free(resultC);
    return respData.data ?? "";
  }

  @override
  String getHostName() {
    // default value is localhost
    return "127.0.0.1";
  }

  final _getShareInfo = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetShareInfo');

// RestoreFromOldVersionData
  final RestoreFromOldVersionData = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('RestoreFromOldVersionData');

  // //export SyncData
  // func SyncData(host *C.char, port int, code int64, syncKind int) *C.char {
  final SyncData = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>, Int64, Int64, Int64),
      Pointer<Utf8> Function(Pointer<Utf8>, int, int, int)>('SyncData');

  // goRuntimeInfo
  final GoBuildInfoString = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(), Pointer<Utf8> Function()>('GoBuildInfoString');

// allSourceHosts
  final AllSourceHosts = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Bool archived),
      Pointer<Utf8> Function(bool archived)>('AllSourceHosts');

// GetAllSources
  final GetAllSources = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetAllSources');

// RefreshPublicSources
  final RefreshPublicSources = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('RefreshPublicSources');
  //   // func (c *Client) AddSourcesToDB(ctx context.Context, sources []string) error {
  final AddSourcesToDB = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('AddSourcesToDB');
  // AllSourcesFromDB
  final AllSourcesFromDB = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('AllSourcesFromDB');
  // DeleteSourcesFromDB(ctx context.Context, sources []string) error
  final DeleteSourcesFromDB = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('DeleteSourcesFromDB');
  // getWebOnlineClose
  final GetWebOnlineClose = nativeAddLib
      .lookupFunction<Bool Function(), bool Function()>('GetWebOnlineClose');

  final SetWebOnlineClose =
      nativeAddLib.lookupFunction<Void Function(Bool), void Function(bool)>(
          'SetWebOnlineClose');

  // //export WebOnlinePort
  final WebOnlinePort = nativeAddLib
      .lookupFunction<Int64 Function(), int Function()>('WebOnlinePort');

  @override
  void setWebOnlineClose(bool v) {
    SetWebOnlineClose(v);
  }

  @override
  int webOnlinePort() {
    return WebOnlinePort();
  }

// allWordsByCreateDayAndOrder
  final AllWordsByCreateDayAndOrder = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64, Int64),
      Pointer<Utf8> Function(int, int)>('AllWordsByCreateDayAndOrder');

// checkDictZipTargetPathExist
  final CheckDictZipTargetPathExist = nativeAddLib.lookupFunction<
      Bool Function(Pointer<Utf8>),
      bool Function(Pointer<Utf8>)>('CheckDictZipTargetPathExist');

  @override
  ShareInfo getShareInfo() {
    final resultC = _getShareInfo();
    final RespData<ShareInfo> respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()), (json) => ShareInfo.fromJson(json));
    malloc.free(resultC);
    return respData.data!;
  }

  @override
  RespData<void> newArticleFileInfoBySourceURL(String www) {
    final wordC = www.toNativeUtf8();
    final resultC = NewArticleFileInfoBySourceURL(wordC);
    final respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(wordC);
    malloc.free(resultC);
    return respData;
  }

  @override
  FutureOr<RespData<Article>> renewArticleFileInfo(int id) {
    final resultC = RenewArticleFileInfo(id);
    final respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()), (json) => Article.fromJson(json));
    malloc.free(resultC);
    return respData;
  }

  @override
  FutureOr<RespData<Article>> reparseArticleFileInfo(int id) {
    final resultC = ReparseArticleFileInfo(id);
    final respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()), (json) => Article.fromJson(json));
    malloc.free(resultC);
    return respData;
  }

  @override
  FutureOr<RespData<Map<String, int>>> allKnownWordsMap() {
    final resultC = AllKnownWordsMap();
    final respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) {
      return (json as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int));
    });
    malloc.free(resultC);
    return respData;
  }

  @override
  FutureOr<List<String>> allWordsByCreateDayAndOrder(int createDay, int order) {
    final resultC = AllWordsByCreateDayAndOrder(createDay, order);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final items = List<String>.from(jsonDecode(result));
    return items;
  }

  @override
  bool checkDictZipTargetPathExist(String zipPath) {
    final zipPathC = zipPath.toNativeUtf8();
    final result = CheckDictZipTargetPathExist(zipPathC);
    malloc.free(zipPathC);
    return result;
  }

  @override
  int webDictRunPort() {
    return WebDictRunPort();
  }

  @override
  RespData<void> restoreFromOldVersionData() {
    final resultC = RestoreFromOldVersionData();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  FutureOr<RespData<void>> syncData(
      String ip, int port, int code, int syncKind) {
    final ipC = ip.toNativeUtf8();
    final resultC = SyncData(ipC, port, code, syncKind);
    final result = resultC.toDartString();
    malloc.free(ipC);
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  String goBuildInfoString() {
    final resultC = GoBuildInfoString();
    final result = resultC.toDartString();
    malloc.free(resultC);
    return result;
  }

  @override
  bool getWebOnlineClose() {
    return GetWebOnlineClose();
  }

  @override
  FutureOr<RespData<void>> delProxy() {
    final resultC = _delProxy();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  FutureOr<Translation> translate(String sentence) {
    final sentenceC = sentence.toNativeUtf8();
    final resultC = _translate(sentenceC);
    final result = resultC.toDartString();
    malloc.free(sentenceC);
    malloc.free(resultC);
    final Translation translation = Translation.fromJson(jsonDecode(result));
    return translation;
  }

  @override
  FutureOr<List<HostCount>> allSourceHosts(bool archived) {
    final resultC = AllSourceHosts(archived);
    final result = resultC.toDartString();
    malloc.free(resultC);
    // 判断result是否为空或者为null
    final items = List<HostCount>.from(
        (jsonDecode(result) ?? []).map((e) => HostCount.fromJson(e)));
    return items;
  }

  @override
  FutureOr<List<String>> getAllSources() {
    final resultC = GetAllSources();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final items = List<String>.from(jsonDecode(result) ?? []);
    return items;
  }

  @override
  FutureOr<RespData<void>> refreshPublicSources() {
    final resultC = RefreshPublicSources();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  FutureOr<RespData<void>> addSourcesToDB(String sources) {
    final sourcesC = sources.toNativeUtf8();
    final resultC = AddSourcesToDB(sourcesC);
    final result = resultC.toDartString();
    malloc.free(sourcesC);
    malloc.free(resultC);
    myPrint("addSourcesToDB result: $result");
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  FutureOr<RespData<void>> deleteSourcesFromDB(List<String> sources) {
    final sourcesC = jsonEncode(sources).toNativeUtf8();
    final resultC = DeleteSourcesFromDB(sourcesC);
    final result = resultC.toDartString();
    malloc.free(sourcesC);
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

  @override
  FutureOr<List<String>> allSourcesFromDB() {
    final resultC = AllSourcesFromDB();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final items = List<String>.from(jsonDecode(result) ?? []);
    return items;
  }
}
