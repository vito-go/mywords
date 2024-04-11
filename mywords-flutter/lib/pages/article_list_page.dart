import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler.dart';

import 'package:mywords/pages/article_page.dart';
import 'package:mywords/pages/statistic_chart.dart';
import 'package:mywords/pages/today_known_words.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/util.dart';

import 'package:mywords/common/global_event.dart';
import 'package:mywords/widgets/article_list.dart';

import '../libso/resp_data.dart';

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
    globalEventSubscription?.cancel();
    valueNotifierChart.dispose();
  }

  void globalEventHandler(GlobalEvent event) {
    if (event.eventType == GlobalEventType.syncData && event.param == true) {
      updateTodayCountMap();
    }
    if (event.eventType == GlobalEventType.updateKnownWord) {
      updateTodayCountMap();
    }
    if (event.eventType == GlobalEventType.updateLineChart) {
      updateTodayCountMap();
    }
  }

  @override
  void initState() {
    super.initState();
    updateTodayCountMap();
    globalEventSubscription = subscriptGlobalEvent(globalEventHandler);
  }

  void search() async {
    if (controller.text == "") {
      myToast(context, "网址不能为空");
      return;
    }
    int indexStart = controller.text.indexOf("https://");
    if (indexStart == -1) {
      indexStart = controller.text.indexOf("http://");
    }
    if (indexStart == -1) {
      myToast(context, "网址有误，请检查");
      return;
    }
    final String www = controller.text.substring(indexStart).trim();
    if (www != controller.text) {
      controller.text = www;
    }
    final fileName = await handler.getFileNameBySourceUrl(www);

    if (fileName != "") {
      if (!mounted)return;
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("提示"),
              content: const Text('您已经解析过该网址，是否重新解析？'),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          pushTo(context, ArticlePage(fileName: fileName));
                        },
                        child: const Text("查看")),
                    TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          computeParse(www);
                        },
                        child: const Text("重新解析")),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("取消")),
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
    final respData =
        await compute(computeParseAndSaveArticleFromSourceUrl, www);
    valueNotifier.value = false;
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    controller.text = "";
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateArticleList));
  }

  FocusNode focus = FocusNode();

  Widget textField() {
    //   "https://www.nytimes.com/2024/01/13/world/asia/china-taiwan-election-result-analysis.html"
    return TextField(
      controller: controller,
      focusNode: focus,
      decoration: InputDecoration(
          hintText: "请输入一个英语文章页面网址",
          prefixIcon: IconButton(
              onPressed: () {
                controller.text = '';
              },
              icon: const Icon(
                Icons.clear,
                color: Colors.red,
              )),
          suffixIcon: ValueListenableBuilder(
              valueListenable: valueNotifier,
              builder: (BuildContext context, bool value, Widget? child) {
                return IconButton(
                    onPressed: value ? null : search,
                    icon: value
                        ? const Icon(Icons.access_time)
                        : const Icon(Icons.search));
              })),
    );
  }

  int get count1 => todayCountMap['1'] ?? 0;

  int get count2 => todayCountMap['2'] ?? 0;

  int get count3 => todayCountMap['3'] ?? 0;

  Widget get todaySubtitle {
    final style = prefs.isDark
        ? TextStyle(color: Colors.orange.shade300, fontWeight: FontWeight.bold)
        : TextStyle(
            color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold);
    return RichText(
        text: TextSpan(
            text: "1级: ",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            children: [
          TextSpan(text: '$count1', style: style),
          const TextSpan(text: "  2级: "),
          TextSpan(text: '$count2', style: style),
          const TextSpan(text: "  3级: "),
          TextSpan(text: '$count3', style: style),
        ]));
  }

  StreamSubscription<GlobalEvent>? globalEventSubscription;

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
                  icon: Icon(
                    Icons.wordpress,
                    color: Theme.of(context).primaryColor,
                  )),
              title: RichText(
                text: TextSpan(
                    text: "今日学习单词总数: ",
                    style: TextStyle(
                        color: prefs.isDark ? Colors.white70 : Colors.black),
                    children: [
                      TextSpan(
                          text: "${count1 + count2 + count3}",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
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
                    color: Theme.of(context).primaryColor,
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
      Expanded(
          child: ArticleListView(
        getFileInfos: handler.showFileInfoList,
        toEndSlide: ToEndSlide.archive,
        leftLabel: '归档',
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
    todayCountMap = respData.data ?? {};
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

Future<RespData<void>> computeParseAndSaveArticleFromSourceUrl(
    String www) async {
  final respData = await handler.parseAndSaveArticleFromSourceUrl(www);
  return respData;
}
