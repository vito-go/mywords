import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mywords/widgets/word_common.dart';

import 'package:mywords/libso/handler.dart';

import 'package:mywords/common/queue.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import '../common/global.dart';

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

  void _loadRequest(String word) async {
    final hostname = handler.getHostName();
    String url = await handler.getUrlByWord(hostname, word);
    controller.loadRequest(LoadRequestParams(uri: Uri.parse(url)));
    return;
  }

  void initOpenWithHtmlFilePath() async {
    word = widget.word;
    _loadRequest(word);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WebViewPlatform.instance ??= WebWebViewPlatform();
    initOpenWithHtmlFilePath();
    eventConsumer = consume(eventHandler);
  }

  final controller = PlatformWebViewController(
    const PlatformWebViewControllerCreationParams(),
  );

  Widget get content => loading
      ? const Center(child: CircularProgressIndicator())
      : PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);

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
