import 'dart:convert';

class FileInfo {
  final String title;
  final String fileName;
  final String sourceUrl;
  final int size;
  final int lastModified;
  final bool isDir;
  final int totalCount;
  final int netCount;

  FileInfo({
    required this.sourceUrl,
    required this.title,
    required this.fileName,
    required this.size,
    required this.lastModified,
    required this.isDir,
    required this.totalCount,
    required this.netCount,
  });

  factory FileInfo.fromRawJson(String str) =>
      FileInfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
        sourceUrl: json["sourceUrl"].toString(),
        title: json["title"].toString(),
        fileName: json["fileName"],
        size: json["size"],
        lastModified: json["lastModified"],
        isDir: json["isDir"],
        totalCount: json["totalCount"],
        netCount: json["netCount"],
      );

  Map<String, dynamic> toJson() => {
        "sourceUrl": sourceUrl,
        "title": title,
        "fileName": fileName,
        "size": size,
        "lastModified": lastModified,
        "isDir": isDir,
        "totalCount": totalCount,
        "netCount": netCount,
      };
}

class Article {
  String title;
  int lastModified;
  String version;
  String sourceUrl;
  String htmlContent;
  int minLen;
  int totalCount;
  int netCount;
  List<WordInfo> wordInfos;

  Article({
    required this.version,
    required this.lastModified,
    required this.title,
    required this.sourceUrl,
    required this.htmlContent,
    required this.minLen,
    required this.totalCount,
    required this.netCount,
    required this.wordInfos,
  });

  factory Article.fromRawJson(String str) => Article.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Article.fromJson(Map<String, dynamic> json) {
    final List<dynamic> ws = json["wordInfos"] ?? [];
    return Article(
      title: json["title"].toString(),
      lastModified: json["lastModified"] ?? 0,
      version: json["version"].toString(),
      sourceUrl: json["sourceUrl"].toString(),
      htmlContent: json["htmlContent"],
      minLen: json["minLen"],
      totalCount: json["totalCount"],
      netCount: json["netCount"],
      // wordInfos: List<WordInfo>.from(
      //     json["wordInfos"]??[].map((x) => WordInfo.fromJson(x))),
      wordInfos: List<WordInfo>.generate(
          ws.length, (index) => WordInfo.fromJson(ws[index])),
    );
  }

  Map<String, dynamic> toJson() => {
        "title": title,
        "lastModified": lastModified,
        "version": version,
        "sourceUrl": sourceUrl,
        "htmlContent": htmlContent,
        "minLen": minLen,
        "totalCount": totalCount,
        "netCount": netCount,
        "wordInfos": List<dynamic>.from(wordInfos.map((x) => x.toJson())),
      };
}

class WordInfo {
  String text;
  String wordLink;
  int count;
  List<String> sentence;

  WordInfo({
    required this.text,
    required this.wordLink,
    required this.count,
    required this.sentence,
  });

  factory WordInfo.fromRawJson(String str) =>
      WordInfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory WordInfo.fromJson(Map<String, dynamic> json) => WordInfo(
        text: json["text"] ?? "",
        wordLink: json["wordLink"] ?? "",
        count: json["count"] ?? 0,
        sentence: List<String>.from((json["sentence"] ?? []).map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "wordLink": wordLink,
        "count": count,
        "sentence": List<dynamic>.from(sentence.map((x) => x)),
      };
}

class ShareInfo {
  int port;
  int code;
  bool open;

  ShareInfo({
    required this.port,
    required this.code,
    required this.open,
  });

  factory ShareInfo.fromRawJson(String str) =>
      ShareInfo.fromJson(json.decode(str));

  factory ShareInfo.fromJson(Map<String, dynamic> json) => ShareInfo(
        port: json["port"] ?? 0,
        code: json["code"] ?? 0,
        open: json["open"] ?? false,
      );
}
