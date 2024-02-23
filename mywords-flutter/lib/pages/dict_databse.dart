import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/dict.dart';
import '../util/path.dart';
import '../util/util.dart';

class _DictDirName {
//   	type t struct {
// 		Path string `json:"Path,omitempty"`
// 		Name    string `json:"name,omitempty"`
// 	}
  String basePath = '';
  String title = '';

  _DictDirName(this.basePath, this.title);
}

class DictDatabase extends StatefulWidget {
  const DictDatabase({super.key});

  @override
  State createState() {
    return _State();
  }
}

/// blockShowDialog 阻塞 试验
Future<void> blockShowDialog(BuildContext context, Future<void> future) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        const waiting = UnconstrainedBox(
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(),
          ),
        );
        return FutureBuilder(
            future: future,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              myPrint("snapShot: ${snapshot.data}");
              //snapshot就是_calculation在时间轴上执行过程的状态快照
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return waiting;
                case ConnectionState.waiting:
                  return waiting;
                case ConnectionState.active:
                  return waiting;
                case ConnectionState.done:
                  Future.delayed(const Duration(milliseconds: 0), () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                  myPrint("done ------------");
                  return const Text("");
              }
            });
      });
}

class _State extends State<DictDatabase> {
  List<_DictDirName> dictDirNames = [];

  String get defaultDictBasePath => getDefaultDict().data ?? '';

  Widget buildDictDirNames() {
    return ListView.separated(
        itemBuilder: (context, index) {
          final s = dictDirNames[index];
          bool isDefault = s.basePath == defaultDictBasePath;
          return ListTile(
            title: Text(s.title),
            onTap: isDefault
                ? null
                : () {
                    blockShowDialog(context, () async {
                      await compute(
                          (message) => setDefaultDict(message), s.basePath);
                      initDictDirNames();
                      setState(() {});
                    }());
                    return;
                  },
            subtitle: Text(isDefault ? "${s.basePath} (默认)" : s.basePath),
            trailing: IconButton(
                onPressed: () {
                  setState(() {
                    dictDirNames.removeAt(index);
                  });
                  final t = Timer(const Duration(milliseconds: 4000), () async {
                    final respData = delDict(s.basePath);
                    if (respData.code!=0){
                      myToast(context, respData.message);
                    }
                  });
                  // Then show a snackbar.
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('字典已删除: ${s.title}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    action: SnackBarAction(
                        label: "撤销",
                        onPressed: () {
                          t.cancel();
                          initDictDirNames();
                          setState(() {});
                          return;
                        }),
                  ));
                },
                icon: const Icon(Icons.delete, color: Colors.red)),
          );
        },
        separatorBuilder: (context, index) {
          return const Divider();
        },
        itemCount: dictDirNames.length);
  }

  void initDictDirNames() {
    final respData = dictList();
    final data = respData.data ?? [];
    dictDirNames.clear();
    for (Map<String, dynamic> ele in data) {
      dictDirNames.add(_DictDirName(ele['basePath'], ele['title']));
    }
  }

  @override
  void initState() {
    super.initState();
    initDictDirNames();
  }

  @override
  void dispose() {
    super.dispose();
  }


  bool isSyncing = false;
  bool selectZipFileDone = false;

  Widget syncShareDataBuild() {
    return ElevatedButton.icon(
      onPressed: zipFilePath == "" || isSyncing ? null : _addDict,
      icon: const Icon(Icons.menu_book_outlined),
      label: const Text("开始解析"),
    );
  }

  Widget systemDictButton() {
    return ElevatedButton.icon(
      onPressed: defaultDictBasePath == ""
          ? null
          : () {
              setDefaultDict("");
              setState(() {});
            },
      icon: const Icon(Icons.settings),
      label: const Text("设置默认"),
    );
  }

  void selectZipFilePath() async {
    setState(() {
      selectZipFileDone = true;
    });
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        initialDirectory: getDefaultDownloadDir(),
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['zip']);
    setState(() {
      selectZipFileDone = false;
    });
    if (result == null) {
      return;
    }

    final files = result.files;
    if (files.isEmpty) {
      return;
    }
    final file = files[0];
    if (file.path == null) {
      return;
    }
    setState(() {
      zipFilePath = file.path!;
      myPrint(zipFilePath);
    });
    return;
  }

  void _addDict() async {
    setState(() {
      isSyncing = true;
    });
    final respData = await compute((message) => addDict(message), zipFilePath);
    setState(() {
      isSyncing = false;
    });
    if (respData.code != 0) {
      if (!context.mounted)return;
      myToast(context, "解析失败!\n${respData.message}");
      return;
    }
    if (!context.mounted)return;
    myToast(context, "解析成功");
    initDictDirNames();
    zipFilePath = '';
    setState(() {});
  }

  bool syncToadyWordCount = prefs.syncToadyWordCount;
  String zipFilePath = "";

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
        title: const Text("加载本地词典数据库zip文件"),
        leading: const Tooltip(
          message: "从本地选择zip文件，解析完成后可以清除app缓存和删除原文件",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info),
        ),
        onTap: selectZipFilePath,
        subtitle: selectZipFileDone
            ? const LinearProgressIndicator()
            : Text(zipFilePath),
        trailing: Icon(
          Icons.file_open,
          color: Theme.of(context).primaryColor,
        ),
      ),
      ListTile(
        trailing: syncShareDataBuild(),
        title: isSyncing ? const LinearProgressIndicator() : null,
        leading: const Tooltip(
          message: "加载词典数据库，zip文件格式",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info),
        ),
      ),
      ListTile(
        trailing: systemDictButton(),
        title: const Text("内置词典(简洁版本)"),
        subtitle: Text(defaultDictBasePath == "" ? "默认" : ""),
        leading: const Tooltip(
          message: "内置词典",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info),
        ),
      ),
      Expanded(child: buildDictDirNames())
    ];

    final body = Column(children: children);

    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("设置词典数据库"),
    );
    return Scaffold(
      appBar: appBar,
      body: Padding(padding: const EdgeInsets.all(10), child: body),
    );
  }
}
