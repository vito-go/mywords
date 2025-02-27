import 'dart:async';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/libso/types.dart';

import 'package:mywords/widgets/line_chart.dart';

abstract class Handler {
  FutureOr<void> initLib();

  FutureOr<RespData<void>> newArticleFileInfoBySourceURL(String www);

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

  FutureOr<int> webOnlinePort();

  void setWebOnlineClose(bool v);

  FutureOr<bool> getWebOnlineClose();

  FutureOr<RespData<Article>> articleFromFileInfo(FileInfo fileInfo);

  FutureOr<RespData<Article>> renewArticleFileInfo(int int);

  FutureOr<RespData<Article>> reparseArticleFileInfo(int int);

  RespData<int> vacuumDB();

  FutureOr<RespData<int>> dbSize();

  FutureOr<int> webDictRunPort();

  FutureOr<String> defaultWordMeaning(String word);

  FutureOr<String> dictWordQueryLink(String word);

  FutureOr<FileInfo?> getFileInfoBySourceURL(String sourceURL);

  FutureOr<RespData<void>> setProxyUrl(String netProxy);

  FutureOr<RespData<void>> delProxy();

  FutureOr<String> parseVersion();

  FutureOr<String> proxyURL();

  FutureOr<RespData<void>> shareClosed(int port, int code);

  FutureOr<RespData<void>> shareOpen(int port, int code);

// //export SyncData
// func SyncData(host *C.char, port int, code int64, syncKind int) *C.char {
  // 1 sync known words, 2 sync file infos
  FutureOr<RespData<void>> syncData(
      String ip, int port, int code, int syncKind);

  FutureOr<RespData<ChartLineData>> getChartData();

  FutureOr<RespData<ChartLineData>> getChartDataAccumulate();

  FutureOr<RespData<Map<String, dynamic>>> getToadyChartDateLevelCountMap();

  FutureOr<RespData<Map<String, int>>> allKnownWordsMap();

//  1: id desc, 2: id asc ,3 words desc, 4 words asc  ,createDay 0 mean all
  FutureOr<List<String>> allWordsByCreateDayAndOrder(int createDay, int order);

  FutureOr<RespData<void>> updateKnownWordLevel(String word, int level);

  FutureOr<List<String>?> getIPv4s(); // null mean error

  FutureOr<ShareInfo> getShareInfo();
  FutureOr<List<String>> getAllSources();
  // AllSourcesFromDB
  FutureOr<List<String>> allSourcesFromDB();
// RefreshPublicSources
  FutureOr<RespData<void>> refreshPublicSources();
  RespData<void> restoreFromOldVersionData();
  // func (c *Client) AddSourcesToDB(ctx context.Context, sources string) error {
  FutureOr<RespData<void>> addSourcesToDB(String sources);
  // DeleteSourcesFromDB
  FutureOr<RespData<void>> deleteSourcesFromDB(List<String> sources);
  String getHostName();

  FutureOr<String> goBuildInfoString();

  FutureOr<Translation> translate(String sentence);
  // AllSourceHosts
  FutureOr<List<HostCount>> allSourceHosts(bool archived);
}
