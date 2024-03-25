import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/widgets/word_common.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';

import 'package:mywords/common/global_event.dart';

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
  int realLevel = 0;

  @override
  void dispose() {
    super.dispose();
    player.dispose();
    globalEventSubscription?.cancel();
  }

  final player = AudioPlayer();

  void parseEntry(String url) async {
    // deal_1#deal_sng_2
    url = url.replaceAll('entry://', '');
    final ss = url.split("#");
    if (ss.isEmpty) return;
    final w = Uri.decodeComponent(ss[0]);
    word = w;
    realLevel = await handler.queryWordLevel(word);
    setState(() {});
    _loadHtmlStringByWord(word);
    return;
  }

  void globalEventHandler(GlobalEvent event) {
    if (event.eventType == GlobalEventType.updateKnownWord) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (event.param is Map) {
        if (event.param["word"] != null && event.param["level"] != null) {
          if (word == event.param["word"].toString()) {
            final level = event.param["level"] as int;
            realLevel = level;
            setState(() {});
          }
        }
      }
    }
  }

  StreamSubscription<GlobalEvent>? globalEventSubscription;
  bool loading = false;

  Widget get buildWordHeaderRow {
    List<Widget> children = [
      Expanded(
          child: Text(word, maxLines: 2, style: const TextStyle(fontSize: 20))),
    ];
    if (!word.contains("_") && !word.contains(" ") && !word.contains(",")) {
      children.addAll([
        buildInkWell(context, word, 0, realLevel),
        const SizedBox(width: 5),
        buildInkWell(context, word, 1, realLevel),
        const SizedBox(width: 5),
        buildInkWell(context, word, 2, realLevel),
        const SizedBox(width: 5),
        buildInkWell(context, word, 3, realLevel),
      ]);
    }
    return Row(children: children);
  }

  void initControllerSet() {
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(const Color(0x00000000));
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
    final htmlContent =
        (await handler.getHTMLRenderContentByWord(word)).data ?? '';
    if (htmlContent == "") return;
    controller.loadHtmlString(htmlContent, baseUrl: word);
  }

  void initOpenWithHtmlFilePath() async {
    word = widget.word;
    realLevel = await handler.queryWordLevel(word);
    setState(() {});
    initControllerSet();
    _loadHtmlStringByWord(word);
  }

  @override
  void initState() {
    super.initState();
    initOpenWithHtmlFilePath();
    globalEventSubscription = subscriptGlobalEvent(globalEventHandler);
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
