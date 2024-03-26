import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/widgets/line_chart.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mywords/util/path.dart';
import 'package:mywords/util/util.dart';
import '../util/local_cache.dart';
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

class NonWebHandler implements Interface {
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

//func UpdateKnownWords(level int, c *C.char) *C.char
  final _updateKnownWords = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Int64, Pointer<Utf8>),
      Pointer<Utf8> Function(int, Pointer<Utf8>)>('UpdateKnownWords');

// func parseAndSaveArticleFromSourceUrl(sourceUrl *C.char) *C.char
  final _parseAndSaveArticleFromSourceUrl = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(
          Pointer<Utf8>)>('ParseAndSaveArticleFromSourceUrl');

// func parseAndSaveArticleFromSourceUrl(sourceUrl *C.char) *C.char
  final _parseAndSaveArticleFromFile = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('ParseAndSaveArticleFromFile');

// func ParseAndSaveArticleFromSourceUrlAndContent(sourceUrl *C.char,htmlContent *C.char) *C.char
  final _parseAndSaveArticleFromSourceUrlAndContent =
      nativeAddLib.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Int64),
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>,
              int)>('ParseAndSaveArticleFromSourceUrlAndContent');

// func DeleteGobFile(fileName *C.char) *C.char
  final _deleteGobFile = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('DeleteGobFile');

  @override
  RespData<void> deleteGobFile(String fileName) {
    // // func ShowGobContentByLevel(fileName *C.char, level int) *C.char
    final c = fileName.toNativeUtf8();
    final resultC = _deleteGobFile(c);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(resultC);
    malloc.free(c);
    return respData;
  }

// func ArchiveGobFile(fileName *C.char) *C.char
  final _archiveGobFile = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('ArchiveGobFile');

  @override
  RespData<void> archiveGobFile(String fileName) {
    // // func ShowGobContentByLevel(fileName *C.char, level int) *C.char
    final c = fileName.toNativeUtf8();
    final resultC = _archiveGobFile(c);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    return respData;
  }

// func ArchiveGobFile(fileName *C.char) *C.char
  final _unArchiveGobFile = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('UnArchiveGobFile');

  @override
  RespData<void> unArchiveGobFile(String fileName) {
    // // func ShowGobContentByLevel(fileName *C.char, level int) *C.char
    final c = fileName.toNativeUtf8();
    final resultC = _unArchiveGobFile(c);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    return respData;
  }

// func ShowFileInfoList() *C.char
  final _showFileInfoList = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(), Pointer<Utf8> Function()>('ShowFileInfoList');

  @override
  RespData<List<FileInfo>> showFileInfoList() {
    final c = _showFileInfoList();
    final RespData<List<FileInfo>> respData = RespData.fromJson(
        jsonDecode(c.toDartString()),
        (json) => List<FileInfo>.generate(
            json.length, (index) => FileInfo.fromJson(json[index])));
    malloc.free(c);
    return respData;
  }

// func ArchivedFileInfoList() *C.char
  final _getArchivedFileInfoList = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetArchivedFileInfoList');

  @override
  RespData<List<FileInfo>> getArchivedFileInfoList() {
    final c = _getArchivedFileInfoList();
    final RespData<List<FileInfo>> respData = RespData.fromJson(
        jsonDecode(c.toDartString()),
        (json) => List<FileInfo>.generate(
            json.length, (index) => FileInfo.fromJson(json[index])));
    malloc.free(c);
    return respData;
  }

// func ShowGobContentByLevel(fileName *C.char, level int) *C.char
  final _articleFromGobFile = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>, Int64),
      Pointer<Utf8> Function(Pointer<Utf8>, int)>('ArticleFromGobFile');

  @override
  RespData<Article> articleFromGobFile(String fileName) {
    // // func ShowGobContentByLevel(fileName *C.char, level int) *C.char
    final fileNameC = fileName.toNativeUtf8();
    final c = _articleFromGobFile(fileNameC, 3);
    final RespData<Article> respData = RespData.fromJson(
        jsonDecode(c.toDartString()), (json) => Article.fromJson(json));
    malloc.free(c);
    malloc.free(fileNameC);
    return respData;
  }

// func QueryWordLevel(wordC *C.char) *C.char
  final _queryWordLevel = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('QueryWordLevel');

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

// func LevelDistribute(artC *C.char) *C.char param []string
  final _levelDistribute = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('LevelDistribute');

  //  QueryWordsLevel(words ...string) map[string]WordKnownLevel
  final _queryWordsLevel = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('QueryWordsLevel');

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
  final _dictWordQuery = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('DictWordQuery');

  @override
  RespData<Map<int, int>> levelDistribute(List<String> words) {
    final c = jsonEncode(words).toNativeUtf8();
    final resultC = _levelDistribute(c);
    final respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()),
        (json) => (json as Map<String, dynamic>).map(
            (key, value) => MapEntry(int.parse(key.toString()), value as int)));
    malloc.free(c);
    malloc.free(resultC);
    return respData;
  }

  @override
  Map<String, int> queryWordsLevel(List<String> words) {
    final c = jsonEncode(words).toNativeUtf8();
    final resultC = _queryWordsLevel(c);
    final respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) {
      return (json as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int));
    });
    malloc.free(c);
    malloc.free(resultC);
    return respData.data ?? {};
  }

  @override
  String dictWordQuery(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = _dictWordQuery(wordC);
    final respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()), (json) => json.toString());
    myPrint(resultC.toDartString());
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
  final _shareClosed = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('ShareClosed');

  @override
  RespData<void> shareClosed() {
    final resultC = _shareClosed();
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
  RespData<void> parseAndSaveArticleFromSourceUrl(String www) {
    final sourceUrl = www.toNativeUtf8();
    final resultC = _parseAndSaveArticleFromSourceUrl(sourceUrl);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(resultC);
    malloc.free(sourceUrl);
    return respData;
  }

// compute must be top level function
  @override
  RespData<void> parseAndSaveArticleFromFile(String path) {
    final pathC = path.toNativeUtf8();
    final resultC = _parseAndSaveArticleFromFile(pathC);
    final RespData respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(resultC);
    malloc.free(pathC);
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
  RespData<void> updateKnownWords(int level, String word) {
    final wordC = jsonEncode([word]).toNativeUtf8();
    final resultC = _updateKnownWords(level, wordC);
    final respData =
        RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
    malloc.free(wordC);
    malloc.free(resultC);
    return respData;
  }

  @override
  int queryWordLevel(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = _queryWordLevel(wordC);
    malloc.free(wordC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<int> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as int);
    final int l = respData.data ?? 0;
    return l;
  }

// compute must be top level function
  @override
  RespData<Article> parseAndSaveArticleFromSourceUrlAndContent(
      String www, String htmlContent, int lastModified) {
    final sourceUrlC = www.toNativeUtf8();
    final htmlContentC = htmlContent.toNativeUtf8();
    final resultC = _parseAndSaveArticleFromSourceUrlAndContent(
        sourceUrlC, htmlContentC, lastModified);
    final RespData<Article> respData = RespData<Article>.fromJson(
        jsonDecode(resultC.toDartString()), (json) => Article.fromJson(json));
    malloc.free(resultC);
    malloc.free(sourceUrlC);
    malloc.free(htmlContentC);
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
  final _getUrlByWord = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>('GetUrlByWord');

// getUrlByWord 返回防止携带word参数
  @override
  String getUrlByWord(String hostName, String word) {
    final wordC = word.toNativeUtf8();
    final hostNameC = word.toNativeUtf8();
    final resultC = _getUrlByWord(hostNameC, wordC);
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
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>('UpdateDictName');

  @override
  RespData<void> updateDictName(String dataDir, String name) {
    final dataDirC = dataDir.toNativeUtf8();
    final nameC = name.toNativeUtf8();
    final resultC = _updateDictName(dataDirC, nameC);
    malloc.free(dataDirC);
    malloc.free(nameC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

// func SetDefaultDict(dataDirC *C.char) *C.char {
  final _setDefaultDict = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('SetDefaultDict');

  @override
  RespData<void> setDefaultDict(String basePath) {
    LocalCache.defaultDictBasePath = null;
    final basePathC = basePath.toNativeUtf8();
    final resultC = _setDefaultDict(basePathC);
    malloc.free(basePathC);
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
  RespData<List<dynamic>> dictList() {
    final resultC = _dictList();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<List<dynamic>> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as List<dynamic>);
    return respData;
  }

// func AddDict(dataDirC *C.char) *C.char {

  final _addDict = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('AddDict');

  @override
  RespData<void> addDict(String dataDir) {
    final dataDirC = dataDir.toNativeUtf8();
    final resultC = _addDict(dataDirC);
    malloc.free(dataDirC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<void> respData =
        RespData.fromJson(jsonDecode(result), (json) {});
    return respData;
  }

// func DelDict(basePath *C.char) *C.char {
  final _delDict = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('DelDict');

  @override
  RespData<void> delDict(String basePath) {
    LocalCache.defaultDictBasePath = null;
    final basePathC = basePath.toNativeUtf8();
    final resultC = _delDict(basePathC);
    malloc.free(basePathC);
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

  final _getDefaultDict = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
      Pointer<Utf8> Function()>('GetDefaultDict');

  @override
  RespData<String> getDefaultDict() {
    final resultC = _getDefaultDict();
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData;
  }

  final _getHTMLRenderContentByWord = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('GetHTMLRenderContentByWord');

  final _getFileNameBySourceUrl = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('GetFileNameBySourceUrl');

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
  String getFileNameBySourceUrl(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = _getFileNameBySourceUrl(wordC);
    malloc.free(wordC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data ?? "";
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

  final _finalHtmlBasePathWithOutHtml = nativeAddLib.lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)>('FinalHtmlBasePathWithOutHtml');

  @override
  String finalHtmlBasePathWithOutHtml(String word) {
    final wordC = word.toNativeUtf8();
    final resultC = _finalHtmlBasePathWithOutHtml(wordC);
    malloc.free(wordC);
    final result = resultC.toDartString();
    malloc.free(resultC);
    final RespData<String> respData =
        RespData.fromJson(jsonDecode(result), (json) => json as String);
    return respData.data ?? "";
  }

  final _setLogUrl = nativeAddLib.lookupFunction<
      Void Function(Pointer<Utf8>, Pointer<Utf8>, Bool),
      void Function(Pointer<Utf8>, Pointer<Utf8>, bool)>('SetLogUrl');

  @override
  void setLogUrl(String logUrl, String logNonce) {
    final logUrlC = logUrl.toNativeUtf8();
    final logNonceC = logNonce.toNativeUtf8();
    _setLogUrl(logUrlC, logNonceC, false);
    malloc.free(logUrlC);
    malloc.free(logNonceC);
    return;
  }

// _println equal to _printInfo
  final _println = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
      void Function(Pointer<Utf8>)>('Println');

  final _printWarn = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
      void Function(Pointer<Utf8>)>('PrintWarn');

  final _printInfo = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
      void Function(Pointer<Utf8>)>('PrintInfo');

  final _printError = nativeAddLib.lookupFunction<Void Function(Pointer<Utf8>),
      void Function(Pointer<Utf8>)>('PrintError');
  final setLogDebug = nativeAddLib
      .lookupFunction<Void Function(Bool), void Function(bool)>('SetLogDebug');
  final setLogCallerSkip =
      nativeAddLib.lookupFunction<Void Function(Int64), void Function(int)>(
          'SetLogCallerSkip');

  void printWarn(String msg) {
    final c = msg.toNativeUtf8();
    _printWarn(c);
    malloc.free(c);
  }

  void printInfo(String msg) {
    final c = msg.toNativeUtf8();
    _printInfo(c);
    malloc.free(c);
  }

// equal to printInfo
  @override
  void println(String msg) {
    final c = msg.toNativeUtf8();
    _println(c);
    malloc.free(c);
  }

  void printError(String msg) {
    final c = msg.toNativeUtf8();
    _printError(c);
    malloc.free(c);
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

}
