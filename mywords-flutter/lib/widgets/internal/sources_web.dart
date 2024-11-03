import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/util.dart';

import 'package:mywords/common/queue.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../pages/sources.dart';


Map<String, String> lastViewedURLMap = {};

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
    // controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.loadRequest(LoadRequestParams(uri: Uri.parse(lastViewedURLMap[rootURL] ?? rootURL)));
  }

  @override
  void initState() {
    super.initState();
    initControllerSet();
    eventConsumer = consume(eventHandler);
  }


  final controller = PlatformWebViewController(
    const PlatformWebViewControllerCreationParams(),
  );

  // Widget get content => loading
  //     ? const Center(child: CircularProgressIndicator())
  //     : WebViewWidget(controller: controller);

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = [
      //  返回主页
      IconButton(
        icon: const Icon(Icons.web),
        onPressed: () {
          Navigator.of(context).pop();
          pushTo(context, const Sources());
        },
      ),
      // 返回根网址
      IconButton(
        icon: const Icon(Icons.home_outlined),
        onPressed: () async {
          controller.loadRequest(LoadRequestParams(uri: Uri.parse(rootURL)));
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
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () async {
          controller.reload();
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
      // 提取解析当前网址
      IconButton(
        icon: const Icon(Icons.content_paste_search),
        onPressed: () async {
          final url = await controller.currentUrl();
          myPrint(url);
          if (url == null) {
            myToast(context, "url is null");
            return;
          }
          //   newArticleFileInfoBySourceURL
          final respData = await handler.newArticleFileInfoBySourceURL(url);
          if (respData.code != 0) {
            myToast(context, respData.message);
            return;
          }
          myToast(context, "success");
        },
      ),
    ];
    return getScaffold(context,
        body:PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context),
        appBar: AppBar(actions: actions));
  }
}
