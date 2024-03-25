import 'dart:async';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';
import 'package:mywords/environment.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/path.dart';
import 'package:mywords/util/util.dart';

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
                  return const Text("");
              }
            });
      });
}

class _State extends State<DictDatabase> {
  List<_DictDirName> dictDirNames = [];

  String defaultDictBasePath = '';

  _addDict(String basePath) {
    blockShowDialog(context, () async {
      final respData = await compute(computeSetDefaultDict, basePath);
      if (respData.code != 0) {
        myToast(context, respData.message);
        return;
      }
      initDictDirNames();
      defaultDictBasePath = basePath;
      setState(() {});
    }());
    return;
  }

  Widget buildDictDirNames() {
    return ListView.separated(
        itemBuilder: (context, index) {
          final s = dictDirNames[index];
          final basePath = s.basePath;
          bool isDefault = s.basePath == defaultDictBasePath;
          return ListTile(
            title: Text(
              isDefault ? "${s.title} (默认)" : s.title,
              style: isDefault
                  ? TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor)
                  : null,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: isDefault
                ? null
                : () {
                    _addDict(basePath);
                  },
            trailing: IconButton(
                onPressed: () {
                  setState(() {
                    dictDirNames.removeAt(index);
                  });
                  final t = Timer(const Duration(milliseconds: 4000), () async {
                    final respData = await handler.delDict(s.basePath);
                    if (respData.code != 0) {
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

  void initDictDirNames() async {
    final respData = await handler.dictList();
    final data = respData.data ?? [];
    dictDirNames.clear();
    for (Map<String, dynamic> ele in data) {
      dictDirNames.add(_DictDirName(ele['basePath'], ele['title']));
    }
  }

  void initDefaultDictBasePath() async {
    defaultDictBasePath = (await handler.getDefaultDict()).data ?? "";
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initDictDirNames();
    initDefaultDictBasePath();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool isSyncing = false;
  bool selectZipFileDone = false;

  Widget get systemDictButton {
    return ElevatedButton.icon(
      onPressed: defaultDictBasePath == ""
          ? null
          : () async {
              await handler.setDefaultDict("");
              initDefaultDictBasePath();
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
        withReadStream: kIsWeb,
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
    if (kIsWeb) {
      if (file.readStream == null) return;
    } else {
      if (file.path == null) return;
    }
    setState(() {
      zipFilePath = file.name;
      isSyncing = true;
    });
    final RespData<void> respData;
    if (kIsWeb) {
      respData = await compute(computeAddDictWithFile,
          {"bytes": file.readStream!, "name": file.name});
    } else {
      respData = await compute(computeAddDict, file.path!);
    }
    setState(() {
      isSyncing = false;
    });
    if (respData.code != 0) {
      if (!context.mounted) return;
      myToast(context, "解析失败! ${respData.message}");
      return;
    }
    if (!context.mounted) return;
    myToast(context, "解析成功");
    initDictDirNames();
    zipFilePath = '';
    defaultDictBasePath = (await handler.getDefaultDict()).data ?? "";
    setState(() {});
  }

  String zipFilePath = "";

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
        title: const Text("加载本地词典数据库zip文件"),
        leading: const Tooltip(
          message: "从本地选择zip文件，解析完成后可以清除应用缓存和删除原文件",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info),
        ),
        onTap: isSyncing ? null : selectZipFilePath,
        subtitle: selectZipFileDone
            ? const LinearProgressIndicator()
            : Text(zipFilePath),
        trailing: isSyncing
            ? const Icon(Icons.access_time_rounded)
            : Icon(Icons.file_open, color: Theme.of(context).primaryColor),
      ),
      SizedBox(
        height: 5,
        child: isSyncing ? const LinearProgressIndicator() : const Text(""),
      ),
      ListTile(
        trailing: systemDictButton,
        title: const Text("内置词典(精简版)"),
        subtitle: Text(defaultDictBasePath == "" ? "(默认)" : ""),
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
    return getScaffold(
      context,
      appBar: appBar,
      body: body,
    );
  }
}

Future<RespData<void>> computeAddDict(String dataDir) async {
  return handler.addDict(dataDir);
}

Future<RespData<void>> computeAddDictWithFile(
    Map<String, dynamic> param) async {
  String name = param['name']!;
  Stream<List<int>> bytes = param['bytes']!;
  final dio = Dio();
  const www = "$debugHostOrigin/_addDictWithFile";

  try {
    final Response<String> response = await dio.post(
      www,
      data: bytes,
      queryParameters: {"name": name},
      options: Options(
          responseType: ResponseType.plain,
          validateStatus: (_) {
            return true;
          }),
    );
    if (response.statusCode != 200) {
      return RespData.err(response.data ?? "");
    }
    return RespData.dataOK(null);
  } catch (e) {
    return RespData.err(e.toString());
  }
}

Future<RespData<void>> computeSetDefaultDict(String basePath) async {
  return handler.setDefaultDict(basePath);
}
