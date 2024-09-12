import 'dart:convert';

class FileInfo {
  final String title;
  final String filePath;
  final String sourceUrl;
  final int id;
  final int size;
  final bool archived;
  final int totalCount;
  final int netCount;
  final int updatedAt;
  final int createdAt;

  FileInfo({
    required this.sourceUrl,
    required this.title,
    required this.id,
    required this.filePath,
    required this.size,
    required this.totalCount,
    required this.archived,
    required this.netCount,
    required this.updatedAt,
    required this.createdAt,
  });

  factory FileInfo.fromRawJson(String str) =>
      FileInfo.fromJson(json.decode(str));

  // copyWith方法
  FileInfo copyWith({
    String? sourceUrl,
    String? title,
    String? filePath,
    int? size,
    int? totalCount,
    int? netCount,
    int? updatedAt,
    bool? archived,
    int? createdAt,
    int? id,
  }) {
    return FileInfo(
      sourceUrl: sourceUrl ?? this.sourceUrl,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      size: size ?? this.size,
      totalCount: totalCount ?? this.totalCount,
      netCount: netCount ?? this.netCount,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      id: id ?? this.id,
    );
  }

  String toRawJson() => json.encode(toJson());

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
        sourceUrl: json["sourceUrl"].toString(),
        title: json["title"].toString(),
        filePath: json["filePath"],
        size: json["size"],
        totalCount: json["totalCount"],
        netCount: json["netCount"],
        updatedAt: json["updatedAt"],
        createdAt: json["createdAt"],
        archived: json["archived"],
        id: json["id"],
      );

  Map<String, dynamic> toJson() => {
        "sourceUrl": sourceUrl,
        "title": title,
        "filePath": filePath,
        "size": size,
        "totalCount": totalCount,
        "netCount": netCount,
      };
}

class Article {
  String title;
  String version;
  String sourceUrl;
  String htmlContent;
  int minLen;
  int totalCount;
  int netCount;
  List<WordInfo> wordInfos;

  Article({
    required this.version,
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
