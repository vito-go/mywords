import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mywords/libso/dict.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/widgets/word_header_row.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  bool loading = false;

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

  void _loadHtmlStringByWord(String word) {
    final htmlContent = getHTMLRenderContentByWord(word).data ?? '';
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

  Widget get content => loading
      ? const Center(child: CircularProgressIndicator())
      : WebViewWidget(controller: controller);

  @override
  Widget build(BuildContext context) {
    final col = Column(
      children: [
        ListTile(title: WordHeaderRow(word: word, key: UniqueKey())),
        Expanded(child: content),
      ],
    );
    return col;
  }
}
