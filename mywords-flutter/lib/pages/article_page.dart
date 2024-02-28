import 'dart:async';
import 'dart:convert';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:mywords/common/global_event.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/libso/types.dart';
import 'package:mywords/widgets/word_common.dart';
import 'package:mywords/util/util.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../libso/funcs.dart';
import '../widgets/word_list.dart';

class ArticlePage extends StatefulWidget {
  final String fileName;

  const ArticlePage({super.key, required this.fileName});

  @override
  State<StatefulWidget> createState() {
    return ArticlePageState();
  }
}

enum ContentPreview { words, htmlContent }

class ArticlePageState extends State<ArticlePage> {
  late final String fileName = widget.fileName;
  int showLevel = 0;
  Article? article;
  bool preview = false;
  bool showSentence = true;

  void initArticle() {
    compute((message) => computeArticleFromGobFile3(message), fileName)
        .then((respData) {
      if (respData.code != 0) {
        myToast(context, respData.message);
        return;
      }
      article = respData.data!;
      if (article!.version != parseVersion()) {
        reParseArticle(false);
        return;
      }
      levelCountMap = _levelDistribute();
      setState(() {});
    });
  }

  void reParseArticle(bool updateLastModified) {
    final art = article;
    if (art == null) {
      if (!context.mounted) return;
      myToast(context, "初始化中...");
      return;
    }
    int lastModified = 0; // update
    if (!updateLastModified) {
      lastModified = art.lastModified;
    }
    compute(
        (message) => parseAndSaveArticleFromSourceUrlAndContent(message),
        <String, dynamic>{
          "www": art.sourceUrl,
          "lastModified": lastModified,
          "htmlContent": art.htmlContent,
        }).then((respData) {
      if (respData.code != 0) {
        if (!context.mounted) return;
        myToast(context, respData.message);
        return;
      }
      addToGlobalEvent(
          GlobalEvent(eventType: GlobalEventType.parseAndSaveArticle));
      article = respData.data!;
      levelCountMap = _levelDistribute();
      if (!context.mounted) return;
      myToast(context, "重新从本地文件解析成功！");
      setState(() {});
    });
  }

  void globalEventHandler(GlobalEvent event) {
    if (event.eventType == GlobalEventType.updateKnownWord) {
      setState(() {});
    }
  }

  StreamSubscription<GlobalEvent>? globalEventSubscription;

  @override
  void initState() {
    super.initState();
    initArticle();
    globalEventSubscription = subscriptGlobalEvent(globalEventHandler);
  }

  Map<String, dynamic> levelCountMap = {}; //level: count
  int get count0 => levelCountMap['0'] ?? 0;

  int get count1 => levelCountMap['1'] ?? 0;
  String get count0VsNet {
    if (count0 == 0) return "0%";
    final netCount = article?.netCount;
    if (netCount == null) return "0%";
    return "${(count0 / netCount * 100).toInt()}%";
  }

  int get count2 => levelCountMap['2'] ?? 0;

  int get count3 => levelCountMap['3'] ?? 0;

  Map<String, dynamic> _levelDistribute() {
    final art = article;
    if (art == null) return {};
    final words = List<String>.generate(
        art.wordInfos.length,
        (index) => art.wordInfos[index].wordLink == ""
            ? art.wordInfos[index].text
            : art.wordInfos[index].wordLink);
    final c = jsonEncode(words).toNativeUtf8();
    final resultC = levelDistribute(c);
    final respData = RespData.fromJson(jsonDecode(resultC.toDartString()),
        (json) => json as Map<String, dynamic>);
    malloc.free(c);
    malloc.free(resultC);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return {};
    }
    return respData.data ?? {};
  }

  void _updateKnownWords(int level, String word) {
    final respData = updateKnownWords(level, word);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateKnownWord));
    levelCountMap = _levelDistribute();
    setState(() {});
  }

  List<WordInfo> get wordInfos {
    final art = article;
    if (art == null) return [];
    return art.wordInfos;
  }

  Widget buildWords(List<WordInfo> infos) {
    List<Widget> items = [];
    for (int i = 0; i < infos.length; i++) {
      final info = infos[i];
      final wordLink = dictWordQueryLink(info.wordLink);
      final int l = queryWordLevel(wordLink);
      if (l != showLevel) {
        continue;
      }
      List<Widget> children = [
        Text("[${i + 1}]{${info.count}}"),
        const SizedBox(width: 5),
        Expanded(
          child: InkWell(
              onTap: () {
                showWord(context, wordLink);
              },
              child: Text(
                wordLink,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 20, color: Theme.of(context).primaryColor),
              )),
        ),
        buildInkWell(wordLink, 0, l, _updateKnownWords),
        const SizedBox(width: 6),
        buildInkWell(wordLink, 1, l, _updateKnownWords),
        const SizedBox(width: 6),
        buildInkWell(wordLink, 2, l, _updateKnownWords),
        const SizedBox(width: 6),
        buildInkWell(wordLink, 3, l, _updateKnownWords),
        const SizedBox(width: 16),
      ];

      items.add(Row(children: children));
      if (!showSentence) {
        continue;
      }
      items.add(highlightText(info.sentence.join('\n\n'), [info.text],
          contextMenuBuilder:
              (BuildContext context, EditableTextState editableTextState) {
        return contextMenuBuilder(context, editableTextState);
      }));
    }
    if (!showSentence) {
      return ListView.separated(
          itemBuilder: (BuildContext context, int index) => items[index],
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
          itemCount: items.length);
    }
    return ListView(children: items);
  }

  List<Widget> actions() {
    return [
      IconButton(
          onPressed: () {
            reParseArticle(true);
          },
          icon: const Icon(Icons.refresh)),
      SizedBox(
        width: 80,
        child: TextButton(
            onPressed: () {
              preview = !preview;
              setState(() {});
            },
            child: preview ? const Text("Words") : const Text("Preview")),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();
    globalEventSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: actions(),
    );
    final art = article;
    if (art == null) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    appBar = AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: actions(),
        title:
            Text(art.title, maxLines: 3, style: const TextStyle(fontSize: 14)));
    final children = [
      ListTile(
        title: Text(
          art.sourceUrl,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.blue),
        ),
        onTap: () {
          launchUrlString(art.sourceUrl);
        },
        minVerticalPadding: 0,
        minLeadingWidth: 0,
        trailing: IconButton(
            onPressed: () {
              copyToClipBoard(context, art.sourceUrl);
            },
            icon: const Icon(Icons.copy)),
      ),
      Text(
          "文章词汇量统计\n单词总数: ${art.totalCount}, 去重后: ${art.netCount}, 比率: ${(art.netCount / art.totalCount).toStringAsFixed(2)}"),
      const SizedBox(height: 5),
      Text(
        "词汇分级 (0:陌生, 1级:认识, 2:了解, 3:熟悉)\n0级: $count0 ($count0VsNet)  1级: $count1  2级: $count2  3级: $count3",
      ),
      const Divider(),
    ];
    if (preview) {
      children.add(Expanded(
          child: buildSelectionWordArea(
              HtmlWidget(art.htmlContent, renderMode: RenderMode.listView))));
    } else {
      children.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Tooltip(
            showDuration: Duration(seconds: 15),
            message:
                "说明: 格式为[单词序号]{单词频次}，例如: [3]{9} actor, 排序后actor为第9个单词，在文中出现的频次是9次。\n筛选功能可以按照等级过滤单词。",
            triggerMode: TooltipTriggerMode.tap,
            child: Icon(Icons.info),
          ),
          const Text("分级筛选"),
          buildShowLevel(0, label: "0", onTap: () {
            showLevel = 0;
            setState(() {});
          }, showLevel: showLevel),
          buildShowLevel(1, label: "1", showLevel: showLevel, onTap: () {
            showLevel = 1;
            setState(() {});
          }),
          buildShowLevel(2, label: "2", showLevel: showLevel, onTap: () {
            showLevel = 2;
            setState(() {});
          }),
          buildShowLevel(3, label: "3", showLevel: showLevel, onTap: () {
            showLevel = 3;
            setState(() {});
          }),
          Switch(
              value: showSentence,
              onChanged: (v) {
                setState(() {
                  showSentence = v;
                });
              })
        ],
      ));
      children.add(const SizedBox(height: 10));
      children.add(Expanded(child: buildWords(wordInfos)));
    }
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    return Scaffold(
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: body,
      ),
    );
  }
}
