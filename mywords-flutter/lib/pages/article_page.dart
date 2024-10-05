import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:mywords/common/global.dart';
import 'package:mywords/common/queue.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/libso/types.dart';

import 'package:mywords/widgets/word_common.dart';
import 'package:mywords/util/util.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/widgets/word_list.dart';

class ArticlePage extends StatefulWidget {
  final FileInfo fileInfo;

  const ArticlePage({super.key, required this.fileInfo});

  @override
  State<StatefulWidget> createState() {
    return ArticlePageState();
  }
}

enum ContentPreview { words, htmlContent }

class ArticlePageState extends State<ArticlePage> {
  late final FileInfo fileInfo = widget.fileInfo;
  int showLevel = 0;
  Article? article;
  bool preview = false;
  bool showSentence = true;

  void initArticle() async {
    compute(handler.articleFromFileInfo, fileInfo).then((respData) async {
      if (respData.code != 0) {
        myToast(context, respData.message);
        return;
      }
      article = respData.data!;
      if (article!.version != Global.parseVersion) {
        reParseArticle();
        return;
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void reParseArticle() {
    final art = article;
    if (art == null) {
      if (!context.mounted) return;
      myToast(context, "初始化中...");
      return;
    }
    final id = fileInfo.id;
    compute(handler.reparseArticleFileInfo, id).then((respData) async {
      if (respData.code != 0) {
        if (!context.mounted) return;
        myToast(context, respData.message);
        return;
      }
      produceEvent( EventType.updateArticleList);
      article = respData.data!;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('重新从本地文件解析成功！')));
      setState(() {});
    });
  }

  void eventHandler(Event event) {
    if (event.eventType == EventType.updateKnownWord) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (event.param is Map) {
        if (event.param["word"] != null && event.param["level"] != null) {
          final word = event.param["word"].toString();
          final level = event.param["level"] as int;
          Global.allKnownWordsMap[word] = level;
          setState(() {});
        }
      }
    }
  }

  StreamSubscription<Event>? eventConsumer;

  @override
  void initState() {
    super.initState();
    initArticle();
    eventConsumer = consume(eventHandler);
  }

  Map<int, int> get levelCountMap {
    final art = article;
    if (art == null) return {};
    final words = List<String>.generate(
        art.wordInfos.length,
        (index) => art.wordInfos[index].wordLink == ""
            ? art.wordInfos[index].text
            : art.wordInfos[index].wordLink);
    return Global.levelDistribute(words);
  } //level: count

  int get count0 => levelCountMap[0] ?? 0;

  int get count1 => levelCountMap[1] ?? 0;

  String get count0VsNet {
    if (count0 == 0) return "0%";
    final netCount = article?.netCount;
    if (netCount == null) return "0%";
    return "${(count0 / netCount * 100).toInt()}%";
  }

  int get count2 => levelCountMap[2] ?? 0;

  int get count3 => levelCountMap[3] ?? 0;

  List<WordInfo> get wordInfos {
    final art = article;
    if (art == null) return [];
    return art.wordInfos;
  }

  List<String> get allSentences {
    final art = article;
    if (art == null) return [];
    return art.allSentences;
  }

  Widget buildWords(List<WordInfo> infos) {
    List<Widget> items = [];
    for (int i = 0; i < infos.length; i++) {
      final info = infos[i];
      final wordLink = info.wordLink;
      final int realLevel = Global.allKnownWordsMap[wordLink] ?? 0;
      if (realLevel != showLevel) {
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
                    fontSize: 20, color: Theme.of(context).colorScheme.primary),
              )),
        ),
        buildInkWell(context, wordLink, 0),
        const SizedBox(width: 5),
        buildInkWell(context, wordLink, 1),
        const SizedBox(width: 5),
        buildInkWell(context, wordLink, 2),
        const SizedBox(width: 5),
        buildInkWell(context, wordLink, 3),
      ];

      items.add(Row(children: children));
      if (!showSentence) {
        continue;
      }

      final List<String> sentences = [];
      for (var sentenceId in info.sentenceIds) {
        final sentence = allSentences[sentenceId];
        sentences.add(sentence);
      }
      // 前面带的空格是为了避免中间行单词粘在一起
      items.add(highlightTextSplitBySpace(
          context, sentences.join(' \n\n'), [info.text], contextMenuBuilder:
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
            reParseArticle();
          },
          icon: const Icon(Icons.refresh)),
      previewIcon,
    ];
  }

  @override
  void dispose() {
    super.dispose();
    eventConsumer?.cancel();
  }

  Widget wordLevelRichText() {
    final color = Theme.of(context).textTheme.bodyMedium?.color;
    final colorPrimary = Theme.of(context).colorScheme.primary;
    final levelStyle = TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.normal);
    return RichText(
      text: TextSpan(
          style: const TextStyle(color: Colors.black),
          text: "",
          children: [
            const TextSpan(
                // text: "词汇分级 (0:陌生, L1:认识, 2:了解, 3:熟悉)\n",
                text: "Word Level (0:Unknown, L1:Known, 2:Understand, 3:Familiar)\n",
                style: TextStyle(color: Colors.blueGrey)),
            TextSpan(text: "L0: ", style: TextStyle(color: color)),
            TextSpan(
                text: "$count0 ($count0VsNet)",
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
            TextSpan(text: "  L1: ", style: TextStyle(color: color)),
            TextSpan(text: "$count1", style: levelStyle),
            TextSpan(text: "  L2: ", style: TextStyle(color: color)),
            TextSpan(text: "$count2", style: levelStyle),
            TextSpan(text: "  L3: ", style: TextStyle(color: color)),
            TextSpan(text: "$count3", style: levelStyle),
          ]),
    );
  }

  Widget get getHeaderRow => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Tooltip(
            showDuration: const Duration(seconds: 30),
            message:
                "解析器版本: ${Global.parseVersion}\n说明: 格式为[单词序号]{单词频次}，例如: [3]{9} actor, 排序后actor为第3个单词，在文中出现的频次是9次。\n筛选功能可以按照等级过滤显示单词。",
            triggerMode: TooltipTriggerMode.tap,
            child: const Icon(Icons.info),
          ),
          const Text("Level Filter"),
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
      );

  Widget staticsRichText(int totalCount, int netCount) {
    final color = Theme.of(context).textTheme.bodyMedium?.color;
    return RichText(
        text: TextSpan(
            // text: "词汇量统计: 总数: ",
            text: "Word Count: Total: ",
            style: Theme.of(context).textTheme.titleMedium,
            children: [
          TextSpan(
              text: "$totalCount",
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          // const TextSpan(text: ", 去重后: "),
          const TextSpan(text: ", Net: "),
          TextSpan(
              text: "$netCount",
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          // const TextSpan(text: ", 比率: "),
          const TextSpan(text: ", Rate: "),
          TextSpan(
              text: (netCount / totalCount).toStringAsFixed(2),
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ]));
  }

  Widget get previewIcon {
    return IconButton(
        onPressed: () {
          preview = !preview;
          setState(() {});
        },
        icon: Icon(Icons.preview,
            color: preview ? Theme.of(context).colorScheme.primary : null));
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
       actions: actions(),
    );
    final art = article;
    if (art == null) {
      return getScaffold(
        context,
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    appBar = AppBar(
         actions: actions(),
        title:
            Text(art.title, maxLines: 3, style: const TextStyle(fontSize: 14)));
    final children = [
      ListTile(
        title: Text(
          art.sourceUrl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.blue, fontSize: 14),
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
      Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: staticsRichText(art.totalCount, art.netCount),
      ),
      const SizedBox(height: 5),
      Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: wordLevelRichText(),
      ),
      const Divider(),
    ];
    if (preview) {
      children.add(Expanded(
          child: buildSelectionWordArea(
        Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child:
                HtmlWidget(art.htmlContent, renderMode: RenderMode.listView)),
      )));
    } else {
      children.add(getHeaderRow);
      children.add(const SizedBox(height: 8));
      children.add(Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: buildWords(wordInfos))));
    }
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
    return getScaffold(context, appBar: appBar, body: body);
  }
}

Widget contextMenuBuilder(
    BuildContext context, EditableTextState editableTextState) {
  final textEditingValue = editableTextState.textEditingValue;
  final TextSelection selection = textEditingValue.selection;
  final buttonItems = editableTextState.contextMenuButtonItems;
  if (!selection.isCollapsed) {
    final selectText = selection.textInside(textEditingValue.text).trim();
    if (!selectText.contains(" ")) {
      buttonItems.add(ContextMenuButtonItem(
          onPressed: () {
            showWord(context, selectText);
          },
          label: "Lookup"));
    }
  }
  return AdaptiveTextSelectionToolbar.buttonItems(
    buttonItems: buttonItems,
    anchors: editableTextState.contextMenuAnchors,
  );
}
