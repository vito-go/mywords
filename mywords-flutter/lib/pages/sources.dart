import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/pages/get_icon.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/util.dart';

import '../config/config.dart';
import '../widgets/sources.dart';

class Sources extends StatefulWidget {
  const Sources({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<Sources> {
  List<String> sourceURLs = [];

// AllSourcesFromDB
  List<String> allSourcesFromDB = [];

  Future<void> refreshSources() async {
    sourceURLs = await handler.getAllSources();
    allSourcesFromDB = await handler.allSourcesFromDB();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refreshSources();
  }

  bool editing = false;
  Map<String, bool> hostSelectedMap = {};

  Widget buildSourceListTile(String rootURL) {
    Widget leading = getIconBySourceURL(rootURL);
    final fromSourceDB = allSourcesFromDB.contains(rootURL);
    return ListTile(
      title: Text(rootURL),
      leading: leading,
      trailing: editing
          ? Checkbox(
              value: fromSourceDB ? (hostSelectedMap[rootURL] ?? false) : false,
              onChanged: !fromSourceDB
                  ? null
                  : (v) {
                      if (v == null) return;
                      hostSelectedMap[rootURL] = v;
                      setState(() {});
                    })
          : const Icon(Icons.navigate_next),
      onTap: editing
          ? null
          : () {
              // 点击后跳转到对应的页面
              pushTo(context, WordWebView1(rootURL: rootURL));
            },
    );
  }

  final controllerAdd = TextEditingController();

  Widget showAddSourceDialog(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Source"),
      content: TextField(
          controller: controllerAdd,
          minLines: 4,
          maxLines: 10,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: "Please input source url.\nIf multiple, separate by newline",
          )),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("cancel")),
        TextButton(
            onPressed: () async {
              String text = controllerAdd.text;
              text = text.trim();
              if (text.isEmpty) {
                myToast(context, "url is empty");
                return;
              }
              final resp = await handler.addSourcesToDB(text);
              if (!resp.success) {
                myToast(context, "add source failed");
                return;
              }
              myToast(context, "add source success");
              await refreshSources();
              Navigator.pop(context);
            },
            child: const Text("ok"))
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    controllerAdd.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return getScaffold(
      context,
      appBar: AppBar(
        title: const Text("Sources"),
        actions: [
          // refresh
          IconButton(
              onPressed: () async {
                final respRefresh = await handler.refreshPublicSources();
                if (!respRefresh.success) {
                  myToast(context, "refresh sources failed");
                  return;
                }
                await refreshSources();
                myToast(context, "refreshed sources");
              },
              icon: Icon(Icons.refresh)),
          IconButton(
              onPressed: () {
                showDialog(context: context, builder: showAddSourceDialog)
                    .then((value) {
                  controllerAdd.clear();
                });
              },
              icon: Icon(Icons.add)),
          editing
              ? IconButton(
                  onPressed: () async {
                    final selectSourceURLs = hostSelectedMap.keys.toList();
                    if (selectSourceURLs.isEmpty) {
                      setState(() {
                        editing = !editing;
                      });
                      return;
                    }
                    hostSelectedMap.clear();
                    final resp =
                        await handler.deleteSourcesFromDB(selectSourceURLs);
                    setState(() {
                      editing = !editing;
                    });
                    if (!resp.success) {
                      myToast(context, "delete sources from db failed");
                      return;
                    }
                    await refreshSources();

                    myToast(context, "delete success");
                  },
                  icon: Icon(Icons.delete, color: Colors.red))
              : IconButton(
                  onPressed: () async {
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
