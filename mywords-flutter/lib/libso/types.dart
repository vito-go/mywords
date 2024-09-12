import 'dart:convert';

import 'package:mywords/util/util.dart';

class FileInfo {
  final String title;
  final String filePath;
  final String host;
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
    required this.host,
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
    String? host,
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
      host: host ?? this.host,
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
        host: json["host"],
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
        "host": host,
        "filePath": filePath,
        "size": size,
        "totalCount": totalCount,
        "netCount": netCount,
        "updatedAt": updatedAt,
        "createdAt": createdAt,
        "archived": archived,
        "id": id,
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
  List<String> allSentences;
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
    required this.allSentences,
  });

  factory Article.fromRawJson(String str) => Article.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Article.fromJson(Map<String, dynamic> json) {
    final List<dynamic> ws = json["wordInfos"] ?? [];
    final List<dynamic> allSentences = json["allSentences"] ?? [];
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
      // allSentences: List<String>.from(json["allSentences"]??[].map((x) => x)),
      allSentences: List<String>.generate(
          allSentences.length, (index) => allSentences[index]),
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
  String text; //就是word
  String wordLink;
  int count;
  List<int> sentenceIds;

  WordInfo({
    required this.text,
    required this.wordLink,
    required this.count,
    required this.sentenceIds,
  });

  factory WordInfo.fromRawJson(String str) =>
      WordInfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory WordInfo.fromJson(Map<String, dynamic> json) => WordInfo(
        text: json["text"] ?? "",
        wordLink: json["wordLink"] ?? "",
        count: json["count"] ?? 0,
        sentenceIds:
            List<int>.from((json["sentenceIds"] ?? []).map((x) => x as int)),
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "wordLink": wordLink,
        "count": count,
        "sentenceIds": sentenceIds,
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
