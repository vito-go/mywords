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
  bool editing = false;
  Map<String, bool> hostSelectedMap = {};

  Widget buildSourceListTile(String rootURL) {
    Widget leading = const Icon(Icons.link);
    final uri = Uri.tryParse(rootURL);
    if (uri != null) {
      final assetPath = assetPathByHost(uri.host);
      if (assetPath != "") {
        leading =
            ClipOval(child: Image.asset(assetPath, width: 28, height: 28));
      }
    }
    return ListTile(
      title: Text(rootURL),
      leading: leading,
      trailing: editing
          ? Checkbox(
              value: hostSelectedMap[rootURL] ?? false,
              onChanged: (v) {
                if (v == null) return;
                hostSelectedMap[rootURL] = v;
                setState(() {});
              })
          : const Icon(Icons.navigate_next),
      onTap: editing?null:() {
        // 点击后跳转到对应的页面
        pushTo(context, WordWebView1(rootURL: rootURL));
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
          IconButton(onPressed: () {}, icon: Icon(Icons.add)),
          editing
              ? IconButton(
                  onPressed: () {
                    hostSelectedMap.clear();
                    // todo
                    setState(() {
                      editing = !editing;
                    });
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ))
              : IconButton(
                  onPressed: () {
                    setState(() {
                      editing = !editing;
                    });
                  },
                  icon: Icon(Icons.edit_note)),
        ],
      ),
      body: ListView(
        children: [...sourceURLs.map((e) => buildSourceListTile(e))],
      ),
    );
  }
}
