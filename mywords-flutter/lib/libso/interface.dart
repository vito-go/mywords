import 'dart:async';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/libso/types.dart';

import 'package:mywords/widgets/line_chart.dart';

abstract class Handler {
  FutureOr<void> initLib();

  FutureOr<RespData<void>> newArticleFileInfoBySourceURL(String www);

  //readMessage 阻塞性获取消息 0 意味着不超时
  String readMessage();

  // hostname 可以为空，默认localhost
  FutureOr<String> getUrlByWordForWeb(String hostname, String word);

  FutureOr<RespData<void>> updateDictName(int id, String name);

  FutureOr<RespData<void>> setDefaultDict(int id);

  FutureOr<RespData<List<DictInfo>>> dictList();

  FutureOr<RespData<void>> addDict(String dataDir);

  FutureOr<RespData<void>> delDict(int id);

  FutureOr<RespData<List<String>>> searchByKeyWord(String word);

  FutureOr<int> getDefaultDictId();
  FutureOr<bool> checkDictZipTargetPathExist(String zipPath);

  FutureOr<RespData<String>> getHTMLRenderContentByWord(String word);

  FutureOr<bool> existInDict(String word);

  FutureOr<RespData<void>> deleteGobFile(int id);

  FutureOr<RespData<void>> updateFileInfo(FileInfo item);

  FutureOr<RespData<List<FileInfo>>> getFileInfoListByArchived(bool archived);

  FutureOr<Map<String, dynamic>> knownWordsCountMap();

  FutureOr<RespData<Article>> articleFromFileInfo(FileInfo fileInfo);

  FutureOr<RespData<Article>> renewArticleFileInfo(int int);

  FutureOr<RespData<Article>> reparseArticleFileInfo(int int);

  RespData<int> vacuumDB();

  RespData<int> dbSize();
  FutureOr< int> webDictRunPort();

  FutureOr<RespData<String>> backUpData(String zipName, String dataDirPath);

  FutureOr<String> defaultWordMeaning(String word);

  FutureOr<String> dictWordQueryLink(String word);

  FutureOr<FileInfo?> getFileInfoBySourceURL(String sourceURL);

  FutureOr<RespData<void>> setProxyUrl(String netProxy);

  FutureOr<RespData<void>> restoreFromBackUpData(bool syncKnownWords,
      String zipPath, bool syncToadyWordCount, bool syncByRemoteArchived);

  FutureOr<String> parseVersion();

  FutureOr<String> dbExecute(String s);

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

  FutureOr<RespData<Map<String, int>>> allKnownWordsMap();

  FutureOr<RespData<Map<int, List<String>>>> allKnownWordMap();

//  1: id desc, 2: id asc ,3 words desc, 4 words asc  ,createDay 0 mean all
  FutureOr<List<String>> allWordsByCreateDayAndOrder(int createDay, int order);

  FutureOr<RespData<Map<int, List<String>>>> todayKnownWordMap();

  FutureOr<RespData<void>> updateKnownWordLevel(String word, int level);

  FutureOr<List<String>?> getIPv4s(); // null mean error

  FutureOr<RespData<List<String>>> searchByKeyWordWithDefault(String word);

  FutureOr<ShareInfo> getShareInfo();

  RespData<void> dropAndReCreateDB();

  String getHostName();
}
