import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/util.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:mywords/common/queue.dart';

import '../../libso/types.dart';
import '../../pages/sources.dart';

Map<String, String> lastViewedURLMap = {}; // host -> last viewed url

class WordWebView1 extends StatefulWidget {
  const WordWebView1({super.key, required this.rootURL});

  final String rootURL;

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<WordWebView1> {
  late final String rootURL = widget.rootURL;
  bool loading = true;

  @override
  void dispose() {
    super.dispose();
    eventConsumer?.cancel();
  }

  void eventHandler(Event event) {
    if (event.eventType == EventType.updateKnownWord) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  StreamSubscription<Event>? eventConsumer;

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
          lastViewedURLMap[rootURL] = request.url;
          return NavigationDecision.navigate;
        },
      ),
    );
    controller.loadRequest(Uri.parse(lastViewedURLMap[rootURL] ?? rootURL));
  }

  @override
  void initState() {
    super.initState();
    initControllerSet();
    eventConsumer = consume(eventHandler);
  }

  final controller = WebViewController();

  Widget get content => loading
      ? const Center(child: CircularProgressIndicator())
      : WebViewWidget(controller: controller);

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = [
      //  返回主页
      IconButton(
        icon: const Icon(Icons.home),
        onPressed: () {
          Navigator.of(context).pop();
          pushTo(context, Sources());
        },
      ),
      // 返回根网址
      IconButton(
        icon: const Icon(Icons.home_outlined),
        onPressed: () async {
          controller.loadRequest(Uri.parse(rootURL));
        },
      ),
      // 后退
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          if (await controller.canGoBack()) {
            controller.goBack();
          }
        },
      ),
      // 前进
      IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () async {
          if (await controller.canGoForward()) {
            controller.goForward();
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.link),
        onPressed: () async {
          final url = await controller.currentUrl();
          if (url == null) return;
          copyToClipBoard(context, url);
        },
      ),
      // 提取解析当前网址
      IconButton(
        icon: const Icon(Icons.send_and_archive),
        onPressed: () async {
          final url = await controller.currentUrl();
          myPrint(url);
          if (url == null) {
            myToast(context, "url is null");
            return;
          }
          final FileInfo? fInfo = await handler.getFileInfoBySourceURL(url);
          if (fInfo != null) {
            myToast(context,
                "Warn: You have already parsed this URL\n$url\n${fInfo.title}");
            return;
          }
          //   newArticleFileInfoBySourceURL
          final respData = await handler.newArticleFileInfoBySourceURL(url);
          if (respData.code != 0) {
            myToast(context, respData.message);
            return;
          }
          myToast(context, "success");
          produceEvent(EventType.updateArticleList);
        },
      ),
    ];
    return getScaffold(context,
        body: content, appBar: AppBar(actions: actions));
  }
}
