import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/widgets/word_common.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:mywords/libso/handler.dart';

import 'package:mywords/common/queue.dart';

import '../common/prefs/prefs.dart';

class WordWebView extends StatefulWidget {
  const WordWebView({super.key, required this.word});

  final String word;

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<WordWebView> {
  String word = '';

  @override
  void dispose() {
    super.dispose();
    player.dispose();
    eventConsumer?.cancel();
  }

  final player = AudioPlayer();

  void parseEntry(String url) async {
    // deal_1#deal_sng_2
    url = url.replaceAll('entry://', '');
    final ss = url.split("#");
    if (ss.isEmpty) return;
    final w = Uri.decodeComponent(ss[0]);
    word = w;
    setState(() {});
    _loadHtmlStringByWord(word);
    return;
  }

  void eventHandler(Event event) {
    if (event.eventType == EventType.updateKnownWord) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (event.param is Map) {
        if (event.param["word"] != null && event.param["level"] != null) {
          if (word == event.param["word"].toString()) {
            setState(() {});
          }
        }
      }
    }
  }

  StreamSubscription<Event>? eventConsumer;
  bool loading = false;

  Widget get buildWordHeaderRow {
    List<Widget> children = [
      Expanded(
          child: Text(word, maxLines: 2, style: const TextStyle(fontSize: 20))),
    ];
    if (!word.contains("_") && !word.contains(" ") && !word.contains(",")) {
      children.addAll([
        buildInkWell(context, word, 0),
        const SizedBox(width: 5),
        buildInkWell(context, word, 1),
        const SizedBox(width: 5),
        buildInkWell(context, word, 2),
        const SizedBox(width: 5),
        buildInkWell(context, word, 3),
      ]);
    }
    return Row(children: children);
  }

  void initControllerSet() {
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          myPrint("progress ---->  $progress");
        },
        onPageStarted: (String url) {
          setState(() {
            loading = false;
          });
        },
        onPageFinished: (String url) {},
        onUrlChange: (v) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          setState(() {
            loading = true;
          });
          final uri = Uri.parse(request.url);
          myPrint(uri.scheme);
          myPrint(request.url);

          if (uri.scheme == "entry") {
            myPrint(uri.host);
            parseEntry(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  void _loadHtmlStringByWord(String word) async {
    var htmlContent =
        (await handler.getHTMLRenderContentByWord(word)).data ?? '';
    if (htmlContent == "") return;
    // final isDark = prefs.isDark;
    // if (isDark) {
    //   htmlContent =
    //       "<style>body{background-color: #FFE0B2FF;}</style>$htmlContent";
    // }
    controller.loadHtmlString(htmlContent, baseUrl: word);
  }

  void initOpenWithHtmlFilePath() async {
    word = widget.word;
    setState(() {});
    initControllerSet();
    _loadHtmlStringByWord(word);
  }

  @override
  void initState() {
    super.initState();
    initOpenWithHtmlFilePath();
    eventConsumer = consume(eventHandler);
  }

  final controller = WebViewController();

  Widget get content => loading
      ? const Center(child: CircularProgressIndicator())
      : WebViewWidget(controller: controller);

  @override
  Widget build(BuildContext context) {
    final col = Column(
      children: [
        ListTile(title: buildWordHeaderRow),
        Expanded(child: content),
      ],
    );
    return col;
  }
}
