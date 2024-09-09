import 'dart:async';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/libso/types.dart';

import 'package:mywords/widgets/line_chart.dart';

abstract class Handler {
  FutureOr<void> initLib();

  FutureOr<RespData<void>> parseAndSaveArticleFromSourceUrl(String www);

  FutureOr<RespData<void>> parseAndSaveArticleFromFile(String path);

  // hostname 可以为空，默认localhost
  FutureOr<String> getUrlByWord(String hostname, String word);

  FutureOr<RespData<void>> updateDictName(String dataDir, String name);

  FutureOr<RespData<void>> setDefaultDict(String basePath);

  FutureOr<RespData<List<dynamic>>> dictList();

  FutureOr<RespData<void>> addDict(String dataDir);

  FutureOr<RespData<void>> delDict(String basePath);

  FutureOr<RespData<List<String>>> searchByKeyWord(String word);

  FutureOr<RespData<String>> getDefaultDict();

  FutureOr<RespData<String>> getHTMLRenderContentByWord(String word);

  FutureOr<String> finalHtmlBasePathWithOutHtml(String word);

  FutureOr<RespData<void>> deleteGobFile(int id);

  FutureOr<RespData<void>> updateFileInfo(FileInfo item);

  FutureOr<RespData<List<FileInfo>>> showFileInfoList();

  FutureOr<RespData<List<FileInfo>>> getArchivedFileInfoList();

  FutureOr<Map<String, dynamic>> knownWordsCountMap();

  FutureOr<RespData<Article>> articleFromGobFile(String fileName);

  FutureOr<RespData<String>> backUpData(String zipName, String dataDirPath);

  FutureOr<String> dictWordQuery(String word);

  FutureOr<RespData<Map<int, int>>> levelDistribute(List<String> words);

  FutureOr<String> dictWordQueryLink(String word);

  FutureOr<String> getFileNameBySourceUrl(String word);

  FutureOr<RespData<void>> setProxyUrl(String netProxy);

  FutureOr<RespData<void>> restoreFromBackUpData(bool syncKnownWords,
      String zipPath, bool syncToadyWordCount, bool syncByRemoteArchived);

  FutureOr<String> parseVersion();

  FutureOr<String> proxyURL();

  FutureOr<RespData<void>> shareClosed();

  FutureOr<RespData<void>> shareOpen(int port, int code);

  FutureOr<RespData<void>> restoreFromShareServer(
      String ip,
      int port,
      int code,
      bool syncKnownWords,
      String tempDir,
      bool syncToadyWordCount,
      bool syncByRemoteArchived);

  FutureOr<RespData<ChartLineData>> getChartData();

  FutureOr<RespData<ChartLineData>> getChartDataAccumulate();

  FutureOr<RespData<Map<String, dynamic>>> getToadyChartDateLevelCountMap();

  FutureOr<RespData<Map<int, List<String>>>> allKnownWordMap();

  FutureOr<RespData<Map<int, List<String>>>> todayKnownWordMap();

  FutureOr<RespData<void>> updateKnownWords(int level, String word);

  FutureOr<int> queryWordLevel(String word);

  FutureOr<Map<String, int>> queryWordsLevel(List<String> words);

  FutureOr<List<String>?> getIPv4s(); // null mean error

  FutureOr<RespData<Article>> parseAndSaveArticleFromSourceUrlAndContent(
      String www, String htmlContent, int lastModified);

  FutureOr<RespData<List<String>>> searchByKeyWordWithDefault(String word);

  FutureOr<ShareInfo> getShareInfo();

  void setLogUrl(String logUrl, String logNonce);

  void println(String msg);

  String getHostName();
}
