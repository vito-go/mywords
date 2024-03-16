import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/widgets/line_chart.dart';

import '../util/path.dart';
import '../util/util.dart';
import 'init.dart';
import 'types.dart';
import 'dart:io';

import 'package:path/path.dart' as path;

// func Init(dataDir *C.char, proxyUrl *C.char)
final init = nativeAddLib.lookupFunction<
    Void Function(Pointer<Utf8>, Pointer<Utf8>),
    void Function(Pointer<Utf8>, Pointer<Utf8>)>('Init');

//func UpdateKnownWords(level int, c *C.char) *C.char
final _updateKnownWords = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Int64, Pointer<Utf8>),
    Pointer<Utf8> Function(int, Pointer<Utf8>)>('UpdateKnownWords');

// func parseAndSaveArticleFromSourceUrl(sourceUrl *C.char) *C.char
final _parseAndSaveArticleFromSourceUrl = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('ParseAndSaveArticleFromSourceUrl');
// func parseAndSaveArticleFromSourceUrl(sourceUrl *C.char) *C.char
final _parseAndSaveArticleFromFile = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('ParseAndSaveArticleFromFile');

// func ParseAndSaveArticleFromSourceUrlAndContent(sourceUrl *C.char,htmlContent *C.char) *C.char
final _parseAndSaveArticleFromSourceUrlAndContent = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Int64),
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>,
        int)>('ParseAndSaveArticleFromSourceUrlAndContent');

// func DeleteGobFile(fileName *C.char) *C.char
final _deleteGobFile = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('DeleteGobFile');

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

RespData<void> unArchiveGobFile(String fileName) {
  // // func ShowGobContentByLevel(fileName *C.char, level int) *C.char
  final c = fileName.toNativeUtf8();
  final resultC = _unArchiveGobFile(c);
  final RespData respData =
      RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
  return respData;
}

// func ShowFileInfoList() *C.char
final _showFileInfoList = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('ShowFileInfoList');

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

RespData<Article> computeArticleFromGobFile3(String fileName) {
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
RespData<String> backUpData(Map<String, String> param) {
  final String zipName = param['zipName']!;
  final String dataDirPath = param['dataDirPath']!;
  final downloadDir = getDefaultDownloadDir();
  if (downloadDir == null) {
    return RespData.err("downloadDir is null");
  }
  final downloadPathZip = path.join(downloadDir, "$zipName.zip");
  myPrint(downloadPathZip);
  if (File(downloadPathZip).existsSync()) {
    return RespData.err("文件已存在，请删除或者修改备份文件名: $zipName.zip");
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
final levelDistribute = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('LevelDistribute');
// func SetProxyUrl(netProxy *C.char) *C.char {
final setProxyUrl = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('SetProxyUrl');

// func DictWordQuery(wordC *C.char) *C.char //查不到就是空
final _dictWordQuery = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('DictWordQuery');

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
    Pointer<Utf8> Function(Bool, Pointer<Utf8>, Bool,Bool),
    Pointer<Utf8> Function(bool, Pointer<Utf8>, bool,bool)>('RestoreFromBackUpData');

RespData<void> restoreFromBackUpData(
    bool syncKnownWords, String zipPath, bool syncToadyWordCount,bool syncByRemoteArchived) {
  final pathC = zipPath.toNativeUtf8();
  final resultC =
      _restoreFromBackUpData(syncKnownWords, pathC, syncToadyWordCount,syncByRemoteArchived);
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
final knownWordsCountMap = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('KnownWordsCountMap');

final _parseVersion = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('ParseVersion');

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
final _todayKnownWordMap = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('TodayKnownWordMap');

// func GetToadyChartDateLevelCountMap() *C.char
final _getToadyChartDateLevelCountMap = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('GetToadyChartDateLevelCountMap');

// func RestoreFromShareServer(ipC *C.char, port int, code int64,syncKnownWords bool, tempDir *C.char) *C.char {
final _restoreFromShareServer = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(
        Pointer<Utf8>, Int64, Int64, Bool, Pointer<Utf8>, Bool,Bool),
    Pointer<Utf8> Function(Pointer<Utf8>, int, int, bool, Pointer<Utf8>,
        bool,bool)>('RestoreFromShareServer');

// func ShareClosed( ) *C.char
final _shareClosed = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('ShareClosed');

RespData<void> shareClosed() {
  final resultC = _shareClosed();
  final RespData respData =
      RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
  malloc.free(resultC);
  return respData;
}

RespData<void> shareOpen(int port, int code) {
  final resultC = _shareOpen(port, code);
  final RespData respData =
      RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
  malloc.free(resultC);
  return respData;
}

Future<RespData<void>> restoreFromShareServer(String ip, int port, int code,
    bool syncKnownWords, String tempDir, bool syncToadyWordCount,bool syncByRemoteArchived) async {
  final tempDirC = tempDir.toNativeUtf8();
  final ipC = ip.toNativeUtf8();
  final resultC = _restoreFromShareServer(
      ipC, port, code, syncKnownWords, tempDirC, syncToadyWordCount,syncByRemoteArchived);
  final RespData respData =
      RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
  malloc.free(resultC);
  malloc.free(ipC);
  malloc.free(tempDirC);
  return respData;
}

RespData<ChartLineData> getChartData() {
  final resultC = _getChartData();
  final RespData<ChartLineData> respData = RespData.fromJson(
      jsonDecode(resultC.toDartString()),
      (json) => ChartLineData.fromJson(json));
  malloc.free(resultC);
  return respData;
}

RespData<ChartLineData> getChartDataAccumulate() {
  final resultC = _getChartDataAccumulate();
  final RespData<ChartLineData> respData = RespData.fromJson(
      jsonDecode(resultC.toDartString()),
      (json) => ChartLineData.fromJson(json));
  malloc.free(resultC);
  return respData;
}

// compute must be top level function
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
RespData<Map<String, dynamic>> getToadyChartDateLevelCountMap() {
  final resultC = _getToadyChartDateLevelCountMap();
  final RespData<Map<String, dynamic>> respData = RespData.fromJson(
      jsonDecode(resultC.toDartString()),
      (json) => json as Map<String, dynamic>);
  malloc.free(resultC);
  return respData;
}

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

RespData<void> updateKnownWords(int level, String word) {
  final wordC = jsonEncode([word]).toNativeUtf8();
  final resultC = _updateKnownWords(level, wordC);
  final respData =
      RespData.fromJson(jsonDecode(resultC.toDartString()), (json) => null);
  malloc.free(wordC);
  malloc.free(resultC);
  return respData;
}

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
RespData<Article> parseAndSaveArticleFromSourceUrlAndContent(
    Map<String, dynamic> param) {
  final String www = param['www'].toString();
  final String htmlContent = param['htmlContent'].toString();
  final int lastModified = param['lastModified'] ?? 0;
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

RespData<List<String>> searchByKeyWordWithDefault(String word) {
  final wordC = word.toNativeUtf8();
  final resultC = _searchByKeyWordWithDefault(wordC);
  malloc.free(wordC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<List<String>> respData =
      RespData.fromJson(jsonDecode(result), (json) => List<String>.from(json));
  return respData;
}
