import 'package:flutter/material.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/pages/get_icon.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/util.dart';

import '../widgets/sources_native.dart';

class Sources extends StatefulWidget {
  const Sources({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<Sources> {
  List<String> sourceURLs = [];
  bool init = false;

  List<String> allSourcesFromDB = [];

  Future<void> updateSources() async {
    sourceURLs = await handler.getAllSources();
    allSourcesFromDB = await handler.allSourcesFromDB();
    init = true;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateSources();
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
              pushTo(context, SourcesWebView(rootURL: rootURL));
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
            hintText:
                "Please input source url. One url per line. Example: \n\nhttps://www.nytimes.com/\nhttps://www.bbc.com/",
          )),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel")),
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
              await updateSources();
              Navigator.pop(context);
            },
            child: const Text("OK"))
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    controllerAdd.dispose();
  }

  Widget get addButton => IconButton(
      onPressed: () {
        showDialog(context: context, builder: showAddSourceDialog)
            .then((value) {
          controllerAdd.clear();
        });
      },
      icon: Icon(Icons.add));

  Widget get deleteButton => IconButton(
      onPressed: () async {
        final selectSourceURLs = hostSelectedMap.keys.toList();
        if (selectSourceURLs.isEmpty) {
          setState(() {
            editing = !editing;
          });
          return;
        }
        hostSelectedMap.clear();
        final resp = await handler.deleteSourcesFromDB(selectSourceURLs);
        setState(() {
          editing = !editing;
        });
        if (!resp.success) {
          myToast(context, "delete sources from db failed");
          return;
        }
        await updateSources();

        myToast(context, "delete success");
      },
      icon: Icon(Icons.delete, color: Colors.red));

  Widget get editingButton => IconButton(
      onPressed: () async {
        setState(() {
          editing = !editing;
        });
      },
      icon: Icon(Icons.edit_note));

  Widget get refreshButton => IconButton(
      onPressed: () async {
        final respRefresh = await handler.refreshPublicSources();
        if (!respRefresh.success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('refresh sources failed',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ));
          return;
        }
        await updateSources();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('refresh sources success',
                maxLines: 1, overflow: TextOverflow.ellipsis)));
      },
      icon: Icon(Icons.refresh));

  Widget get copySourceSelectedButton => IconButton(
      onPressed: () async {
        copyToClipBoard(context, sourceURLs.join("\n"));
      },
      icon: Icon(Icons.copy_all));

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (!init) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final listView = ListView.builder(
        itemBuilder: (context, index) {
          final rootURL = sourceURLs[index];
          return buildSourceListTile(rootURL);
        },
        itemCount: sourceURLs.length,
      );
      body = listView;
    }
    final List<Widget> actions = [];
    if (editing) {
      actions.addAll([
        refreshButton,
        copySourceSelectedButton,
        deleteButton,
      ]);
    } else {
      actions.addAll([
        refreshButton,
        addButton,
        editingButton,
      ]);
    }
    final Widget cancelButton = IconButton(
        onPressed: () {
          setState(() {
            editing = false;
          });
        },
        icon: Icon(Icons.cancel_outlined));
    final appBar = AppBar(
      leading: editing ? cancelButton : null,
      title: const Text("Sources"),
      actions: actions,
    );
    return getScaffold(context, appBar: appBar, body: body);
  }
}
