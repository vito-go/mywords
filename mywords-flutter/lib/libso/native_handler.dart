import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mywords/common/global.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/widgets/line_chart.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mywords/util/path.dart';
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
      Pointer<Utf8> Function(Pointer<Utf8>, Int64),
      Pointer<Utf8> Function(Pointer<Utf8>, int)>('UpdateKnownWordLevel');

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

// func BackUpData(targetZipPath, srcDataPath string) error
  final _backUpData = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>('BackUpData');

// param includes zipName and dataDirPath
  @override
  RespData<String> backUpData(String zipName, String dataDirPath) {
    final downloadDir = getDefaultDownloadDir();
    if (downloadDir == null) {
      return RespData.err("downloadDir is null");
    }
    final downloadPathZip = path.join(downloadDir, zipName);
    myPrint(downloadPathZip);
    if (File(downloadPathZip).existsSync()) {
      return RespData.err("文件已存在，请删除或者修改备份文件名: $zipName");
    }
    final downloadPathC = downloadPathZip.toNativeUtf8();
    final srcC = dataDirPath.toNativeUtf8();
    final resultC = _backUpData(downloadPathC, srcC);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => '');
    malloc.free(downloadPathC);
    malloc.free(srcC);
    malloc.free(resultC);
    respData.data = downloadPathZip;
    return respData;
  }

// func SetProxyUrl(netProxy *C.char) *C.char {
  final _setProxyUrl = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('SetProxyUrl');

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

// func RestoreFromBackUpData(syncKnownWords bool, zipFile *C.char, syncToadyWordCount bool) *C.char {
  final _restoreFromBackUpData = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Bool, Pointer<Utf8>, Bool, Bool),
      Pointer<Utf8> Function(
          bool, Pointer<Utf8>, bool, bool)>('RestoreFromBackUpData');

  @override
  RespData<void> restoreFromBackUpData(bool syncKnownWords, String zipPath,
      bool syncToadyWordCount, bool syncByRemoteArchived) {
    final pathC = zipPath.toNativeUtf8();
    final resultC = _restoreFromBackUpData(
        syncKnownWords, pathC, syncToadyWordCount, syncByRemoteArchived);
    final respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(pathC);
    malloc.free(resultC);
    return respData;
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

// func AllKnownWordMap() *C.char
  final _allKnownWordMap = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('AllKnownWordMap');

// func AllKnownWordMap() *C.char
  final _todayKnownWordMap = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(), Pointer<Utf8> Function()>('TodayKnownWordMap');

// func GetToadyChartDateLevelCountMap() *C.char
  final _getToadyChartDateLevelCountMap = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetToadyChartDateLevelCountMap');

// func RestoreFromShareServer(ipC *C.char, port int, code int64,syncKnownWords bool, tempDir *C.char) *C.char {
  final _restoreFromShareServer = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(
          Pointer<Utf8>, Int64, Int64, Bool, Pointer<Utf8>, Bool, Bool),
      Pointer<Utf8> Function(Pointer<Utf8>, int, int, bool, Pointer<Utf8>, bool,
          bool)>('RestoreFromShareServer');

// func ShareClosed( ) *C.char
  final _shareClosed = nativeAddLib.lookupFunction<Pointer<Utf8> Function(Int64,Int64),
      Pointer<Utf8> Function(int,int)>('ShareClosed');

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
  RespData<void> restoreFromShareServer(
      String ip,
      int port,
      int code,
      bool syncKnownWords,
      String tempDir,
      bool syncToadyWordCount,
      bool syncByRemoteArchived) {
    final tempDirC = tempDir.toNativeUtf8();
    final ipC = ip.toNativeUtf8();
    final resultC = _restoreFromShareServer(ipC, port, code, syncKnownWords,
        tempDirC, syncToadyWordCount, syncByRemoteArchived);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(resultC);
    malloc.free(ipC);
    malloc.free(tempDirC);
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
  RespData<Map<int, List<String>>> allKnownWordMap() {
    final resultC = _allKnownWordMap();
    final RespData<Map<int, List<String>>> respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) {
      Map<int, List<String>> result = {};
      final data = json as Map<String, dynamic>;
      for (var entry in data.entries) {
        final List<dynamic> words = entry.value;
        result[int.parse(entry.key)] = List<String>.generate(
            words.length, (index) => (words[index].toString()));
      }
      return result;
    });
    malloc.free(resultC);
    return respData;
  }

  @override
  RespData<Map<int, List<String>>> todayKnownWordMap() {
    final resultC = _todayKnownWordMap();
    final RespData<Map<int, List<String>>> respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) {
      Map<int, List<String>> result = {};
      final data = json as Map<String, dynamic>;
      for (var entry in data.entries) {
        final List<dynamic> words = entry.value;
        result[int.parse(entry.key)] = List<String>.generate(
            words.length, (index) => (words[index].toString()));
      }
      return result;
    });
    malloc.free(resultC);

    return respData;
  }

  @override
  RespData<void> updateKnownWordLevel(String word, int level) {
    final wordC = word.toNativeUtf8();
    final resultC = UpdateKnownWordLevel(wordC, level);
    final respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(wordC);
    malloc.free(resultC);
    return respData;
  }

// func SearchByKeyWord(keyWordC *C.char) *C.char {}
  final _searchByKeyWordWithDefault = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('SearchByKeyWordWithDefault');

  @override
  RespData<List<String>> searchByKeyWordWithDefault(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = _searchByKeyWordWithDefault(wordC);
    malloc.free(wordC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<List<String>> respData = RespData.fromJson(
        jsonDecode(result), (json) => List<String>.from(json));
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
    Global.defaultDictId = 0;
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
    Global.defaultDictId = 0;
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
    return "";
  }

  final _getShareInfo = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetShareInfo');
  final DropAndReCreateDB = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(), Pointer<Utf8> Function()>('DropAndReCreateDB');
// RestoreFromOldVersionData
  final RestoreFromOldVersionData = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('RestoreFromOldVersionData');
  // //export SyncData
  // func SyncData(host *C.char, port int, code int64, syncKind int) *C.char {
  final SyncData = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>, Int64, Int64, Int64),
      Pointer<Utf8> Function(Pointer<Utf8>, int, int, int)>('SyncData');
  // DBExecute
  final DBExecute = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('DBExecute');

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
  RespData<void> dropAndReCreateDB() {
    final resultC = DropAndReCreateDB();
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(resultC);
    return respData;
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
  FutureOr<String> dbExecute(String s) {
    final sC = s.toNativeUtf8();
    final resultC = DBExecute(sC);
    final result = resultC.toDartString();
    malloc.free(sC);
    malloc.free(resultC);
    return result;
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
  FutureOr<RespData<void>> syncData(String ip, int port, int code, int syncKind) {
    final ipC = ip.toNativeUtf8();
    final resultC = SyncData(ipC, port, code, syncKind);
    final result = resultC.toDartString();
    malloc.free(ipC);
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;

  }
}
