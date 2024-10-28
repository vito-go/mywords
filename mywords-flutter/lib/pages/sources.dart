import 'package:flutter/material.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/navigator.dart';

import '../config/config.dart';
import '../widgets/sources.dart';

// 展示一个列表，列表中的每一项是一个来源
class Sources extends StatefulWidget {
  const Sources({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<Sources> {
  //   "cn.nytimes.com": "$_iconPrefix/nytimes.png",
  //   "www.nytimes.com": "$_iconPrefix/nytimes.png",
  //   "www.economist.com": "$_iconPrefix/theeconomist.png",
  //   "www.cnbc.com": "$_iconPrefix/cnbc.png",
  //   "www.nbcnews.com": "$_iconPrefix/cnbc.png",
  //   "www.bbc.com": "$_iconPrefix/bbc.png",
  //   "www.bbc.co.uk": "$_iconPrefix/bbc.png",
  //   "www.thetimes.co.uk": "$_iconPrefix/thetimes.png",
  //   "edition.cnn.com": "$_iconPrefix/cnn.png",
  //   "www.9news.com.au": "$_iconPrefix/9news.png",
  //   "www.washingtonpost.com": "$_iconPrefix/wp.png",
  //   "www.foxnews.com": "$_iconPrefix/foxnews.png",
  //   "apnews.com": "$_iconPrefix/ap.png",
  //   "www.npr.org": "$_iconPrefix/ap.png",
  //   "www.theguardian.com": "$_iconPrefix/theguardian.png",
  //   "www.voanews.com": "$_iconPrefix/voanews.png",
  //   "time.com": "$_iconPrefix/time.png",
  //   "nypost.com": "$_iconPrefix/nypost.png",
  List<String> sourceURLs = [
    "https://cn.nytimes.com",
    "https://www.nytimes.com",
    "https://www.economist.com",
    "https://www.cnbc.com",
    "https://www.nbcnews.com",
    "https://www.bbc.com",
    "https://www.bbc.co.uk",
    "https://www.thetimes.co.uk",
    "https://edition.cnn.com",
    "https://www.9news.com.au",
    "https://www.washingtonpost.com",
    "https://www.foxnews.com",
    "https://apnews.com",
    "https://www.npr.org",
    "https://www.theguardian.com",
    "https://www.voanews.com",
    "https://time.com",
    "https://nypost.com",

  ];

  Widget buildSourceListTile(String sourceUrl) {
    Widget leading = const Icon(Icons.link);
    final uri = Uri.tryParse(sourceUrl);
    if (uri != null) {
      final assetPath = assetPathByHost(uri.host);
      if (assetPath != "") {
        leading =
            ClipOval(child: Image.asset(assetPath, width: 28, height: 28));
      }
    }
    return ListTile(
      title: Text(sourceUrl),
      leading: leading,
      trailing: const Icon(Icons.navigate_next),
      onTap: () {
        // 点击后跳转到对应的页面
        pushTo(context, WordWebView1(rootURL: sourceUrl));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return getScaffold(
      context,
      appBar: AppBar(
        title: const Text("Sources"),
        actions: [
          IconButton(onPressed: (){}, icon: Icon(Icons.add)),
          IconButton(onPressed: (){}, icon: Icon(Icons.edit_note)),
        ],
      ),
      body: ListView(
        children: [...sourceURLs.map((e) => buildSourceListTile(e))],
      ),
    );
  }
}
