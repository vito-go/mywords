import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mywords/libso/dict.dart';
import 'package:mywords/libso/funcs.dart';
import 'package:mywords/util/util.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../common/global_event.dart';
import '../widgets/word_list.dart';

class WordHtml extends StatefulWidget {
  const WordHtml({super.key, required this.word});

  final String word;

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<WordHtml> {
  String word = '';

  @override
  void dispose() {
    super.dispose();
    player.dispose();
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

  void initControllerSet() {
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(const Color(0x00000000));
    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          myPrint("progress ---->  $progress");
        },
        onPageStarted: (String url) {
          myPrint("================start $url");
        },
        onPageFinished: (String url) {},
        onUrlChange: (v) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
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

  void _loadHtmlStringByWord(String word) {
    final htmlContent = getHTMLRenderContentByWord(word).data ?? '';
    myPrint(htmlContent);
    if (htmlContent == "") return;
    controller.loadHtmlString(htmlContent, baseUrl: word);
  }

  void initOpenWithHtmlFilePath() {
    initControllerSet();
    word = widget.word;
    _loadHtmlStringByWord(word);
  }

  @override
  void initState() {
    super.initState();
    initOpenWithHtmlFilePath();
  }

  final controller = WebViewController();

  Widget get buildHtml {
    return WebViewWidget(
      controller: controller,
    );
  }

  void _updateKnownWords(int level, String word) {
    updateKnownWordsCountLineChart(level, word);
    final respData = updateKnownWords(level, word);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateKnownWord));
    setState(() {});
  }

  Widget get buildHeaderRow {
    final l = queryWordLevel(word);

    List<Widget> children = [
      Expanded(
          child: Text(
        word,
        maxLines: 2,
        style: const TextStyle(fontSize: 16),
      )),
    ];
    myPrint(word);
    if (!word.contains("_") && !word.contains(" ") && !word.contains(",")) {
      children.addAll([
        const Expanded(child: Text('')),
        buildInkWell(word, 0, l, _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 1, l, _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 2, l, _updateKnownWords),
        const SizedBox(width: 5),
        buildInkWell(word, 3, l, _updateKnownWords),
      ]);
    }

    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("字典"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [ListTile(title: buildHeaderRow), Expanded(child: buildHtml)],
      ),
    );
  }
}
