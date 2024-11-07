import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/libso/handler.dart';

import 'package:mywords/pages/article_page.dart';
import 'package:mywords/pages/sources.dart';
import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/pages/today_known_words.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/util.dart';

import 'package:mywords/common/queue.dart';
import 'package:mywords/widgets/article_list.dart';

import '../libso/types.dart';

class ArticleListPage extends StatefulWidget {
  const ArticleListPage({super.key});

  @override
  State<ArticleListPage> createState() => _State();
}

class _State extends State<ArticleListPage> with AutomaticKeepAliveClientMixin {
  TextEditingController controller = TextEditingController();
  ValueNotifier<bool> valueNotifier = ValueNotifier(false);

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    focus.dispose();
    valueNotifier.dispose();
    eventConsumer?.cancel();
    valueNotifierChart.dispose();
  }

  void eventHandler(Event event) {
    if (event.eventType == EventType.updateKnownWord) {
      updateTodayCountMap();
    }
    if (event.eventType == EventType.updateLineChart) {
      updateTodayCountMap();
    }
  }

  @override
  void initState() {
    super.initState();
    updateTodayCountMap();
    eventConsumer = consume(eventHandler);
  }

  void search() async {
    if (controller.text == "") {
      myToast(context, "URL cannot be empty");
      return;
    }
    int indexStart = controller.text.indexOf("https://");
    if (indexStart == -1) {
      indexStart = controller.text.indexOf("http://");
    }
    if (indexStart == -1) {
      myToast(context, "The URL is incorrect, please check");
      return;
    }
    final String www = controller.text.substring(indexStart).trim();
    if (www != controller.text) {
      controller.text = www;
    }
    final FileInfo? fInfo = await handler.getFileInfoBySourceURL(www);

    if (fInfo != null) {
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              // title: const Text("提示"),
              title: const Text("Tips"),

              // content: const Text('您已经解析过该网址，是否重新解析？'),
              content: const Text(
                  'You have already parsed this URL, do you want to reparse it?'),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          pushTo(context, ArticlePage(fileInfo: fInfo));
                        },
                        child: const Text("View")),
                    TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          computeParse(www);
                        },
                        child: const Text("Reparse")),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancel")),
                  ],
                )
              ],
            );
          });
      focus.unfocus();
      return;
    }
    focus.unfocus();
    computeParse(www);
  }

  void computeParse(String www) async {
    valueNotifier.value = true;
    final respData = await compute(handler.newArticleFileInfoBySourceURL, www);
    valueNotifier.value = false;
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    controller.text = "";
    produceEvent(EventType.updateArticleList);
  }

  FocusNode focus = FocusNode();

  Widget get searchIcon => ValueListenableBuilder(
      valueListenable: valueNotifier,
      builder: (BuildContext context, bool value, Widget? child) {
        return IconButton(
            onPressed: value ? null : search,
            icon: value
                ? const Icon(Icons.access_time)
                : const Icon(Icons.content_paste_search));
      });

  Widget textField() {
    //   "https://www.nytimes.com/2024/01/13/world/asia/china-taiwan-election-result-analysis.html"
    return TextField(
      controller: controller,
      focusNode: focus,
      decoration: InputDecoration(
          // hintText: "请输入一个英语文章页面网址",
          hintText: "Please enter a web page URL",
          prefixIcon: IconButton(
              onPressed: () {
                controller.text = '';
              },
              icon: const Icon(
                Icons.clear,
                color: Colors.red,
              )),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              searchIcon,
              IconButton(
                icon: const Icon(Icons.web),
                onPressed: () {
                  pushTo(context, Sources());
                },
              ),
            ],
          )),
    );
  }

  int get count1 => todayCountMap['1'] ?? 0;

  int get count2 => todayCountMap['2'] ?? 0;

  int get count3 => todayCountMap['3'] ?? 0;

  Widget get todaySubtitle {
    final style = TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize);

    return RichText(
        text: TextSpan(
            text: "L1: ",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            children: [
          TextSpan(text: '$count1', style: style),
          const TextSpan(text: "  L2: "),
          TextSpan(text: '$count2', style: style),
          const TextSpan(text: "  L3: "),
          TextSpan(text: '$count3', style: style),
        ]));
  }

  StreamSubscription<Event>? eventConsumer;

  Widget buildBody() {
    List<Widget> colChildren = [
      ValueListenableBuilder(
          valueListenable: valueNotifierChart,
          builder: (BuildContext context, Key value, Widget? child) {
            return ListTile(
              leading: IconButton(
                  onPressed: () {
                    pushTo(context, const ToadyKnownWords());
                  },
                  icon: const Icon(Icons.wordpress)),
              title: RichText(
                text: TextSpan(
                    // text: "今日学习单词总数: ",
                    text: "Today's learned words: ",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                    children: [
                      TextSpan(
                          text: "${count1 + count2 + count3}",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.fontSize,
                              fontWeight: FontWeight.bold))
                    ]),
              ),
              subtitle: todaySubtitle,
              minLeadingWidth: 0,
              trailing: IconButton(
                  onPressed: () {
                    pushTo(context, const StatisticChart());
                  },
                  icon: Icon(
                    Icons.stacked_line_chart,
                    color: Theme.of(context).colorScheme.primary,
                  )),
            );
          }),
      Padding(
        padding: const EdgeInsets.only(right: 10, left: 10),
        child: textField(),
      ),
      ValueListenableBuilder(
          valueListenable: valueNotifier,
          builder: (BuildContext context, bool value, Widget? child) {
            if (value) {
              return const SizedBox(
                  height: 5, child: LinearProgressIndicator());
            }
            return const SizedBox(height: 5);
          }),
      const Expanded(
          child: ArticleListView(
        archived: false,
        toEndSlide: ToEndSlide.archive,
        leftLabel: 'Archive',
        leftIconData: Icons.archive,
        pageNo: 1,
      )),
    ];

    return Column(children: colChildren);
  }

  ValueNotifier<Key> valueNotifierChart = ValueNotifier(UniqueKey());
  Map<String, dynamic> todayCountMap = {};

  Future<void> updateTodayCountMap() async {
    final respData = await handler.getToadyChartDateLevelCountMap();
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    todayCountMap = respData.data!;
    valueNotifierChart.value = UniqueKey();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildBody();
  }

  @override
  bool get wantKeepAlive => true;
}
