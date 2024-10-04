import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/queue.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/environment.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/util/get_scaffold.dart';

import 'package:mywords/util/path.dart';
import 'package:mywords/util/util.dart';

import '../libso/types.dart';

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
  List<DictInfo> dictInfos = [];

  setDefaultDict(int id) async {
    blockShowDialog(context, () async {
      final respData = await compute(handler.setDefaultDict, id);
      if (respData.code != 0) {
        myToast(context, respData.message);
        return;
      }
      initDictInfos();
      produceEvent(EventType.updateDict, id);
      setState(() {});
    }());
    return;
  }

  final controllerEdit = TextEditingController();

  Widget buildDictInfo(DictInfo dictInfo) {
    final id = dictInfo.id;
    final name = dictInfo.name;
    final sub =
        "${formatSize(dictInfo.size)} ${formatTime(DateTime.fromMillisecondsSinceEpoch(dictInfo.updateAt))}";
    return ListTile(
      title: Text(
        dictInfo.name,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      minLeadingWidth: 0,
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      leading: Radio(
          value: id,
          groupValue: defaultDictId,
          onChanged: (int? i) {
            if (i == null) return;
            setDefaultDict(id);
          }),
      onLongPress: () {
        controllerEdit.text = name;
        // shouDialog updateDictName
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("修改词典名称"),
                content: TextField(
                  controller: controllerEdit,
                  decoration: const InputDecoration(
                    hintText: "请输入新名称",
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final newName = controllerEdit.text;
                      if (newName.isEmpty) {
                        myToast(context, "名称不能为空");
                        return;
                      }
                      final respData =
                          await handler.updateDictName(id, newName);
                      if (respData.code != 0) {
                        myToast(context, respData.message);
                        return;
                      }
                      initDictInfos();
                      Navigator.of(context).pop();
                    },
                    child: const Text("确定"),
                  ),
                ],
              );
            });
      },
      trailing: IconButton(
          onPressed: () {
            setState(() {
              dictInfos.removeWhere((element) => element.id == id);
            });
            final t = Timer(const Duration(milliseconds: 3500), () async {
              final respData = await handler.delDict(id);
              if (respData.code != 0) {
                myToast(context, respData.message);
                return;
              }
            });
            // Then show a snackbar.
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('字典已删除: $name',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              action: SnackBarAction(
                  label: "撤销",
                  onPressed: () {
                    t.cancel();
                    initDictInfos();
                    return;
                  }),
            ));
          },
          icon: const Icon(Icons.delete, color: Colors.red)),
    );
  }

  Widget buildDictInfos() {
    return ListView.builder(
      itemBuilder: (context, index) {
        final d = dictInfos[index];
        return buildDictInfo(d);
      },
      itemCount: dictInfos.length,
    );
  }

  int defaultDictId = 0;

  void initDictInfos() async {
    final respData = await handler.dictList();
    final data = respData.data ?? [];
    dictInfos = data;
    defaultDictId = await handler.getDefaultDictId();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initDictInfos();
  }

  @override
  void dispose() {
    super.dispose();
    controllerEdit.dispose();
  }

  bool isSyncing = false;
  bool selectZipFileDone = false;

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
    final PlatformFile file = files[0];
    if (kIsWeb) {
      myPrint(
          "字典数据库文件: ${file.name}: file.readStream==null: ${file.readStream == null} file.size: ${file.size} 文件大小: ${file.bytes?.length}");
      if (file.readStream == null) {
        myToast(context, "读取文件失败: file bytes null");
        return;
      }
    } else {
      if (file.path == null) {
        myToast(context, "读取文件失败: file path null");
        return;
      }
    }
    setState(() {
      zipFilePath = file.name;
      isSyncing = true;
    });
    final RespData<void> respData;
    if (kIsWeb) {
      // todo sha1
      respData = await compute(computeAddDictWithFile, {
        "bytes": file.readStream!,
        "name": file.name,
        "fileSize": file.size
      });
      // respData = await sendStream(file.name, file.size,file.readStream!);
    } else {
      final targetExist = await handler.checkDictZipTargetPathExist(file.path!);
      if (targetExist) {
        setState(() {
          isSyncing = false;
        });
        myToast(context, "文件已存在");
        return;
      }
      respData = await compute(handler.addDict, file.path!);
    }
    setState(() {
      isSyncing = false;
    });
    if (respData.code != 0) {
      myToast(context, "解析失败! ${respData.message}");
      return;
    }
    myToast(context, "解析成功");
    initDictInfos();
    zipFilePath = '';
    setState(() {});
  }

  String zipFilePath = "";

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
        title: const Text("加载本地词典数据库zip文件"),
        leading: const Padding(
            padding: EdgeInsets.all(12),
            child: Tooltip(
              message: "从本地选择zip文件，解析完成后可以清除应用缓存和删除原文件",
              triggerMode: TooltipTriggerMode.tap,
              child: Icon(Icons.info),
            )),
        onTap: isSyncing ? null : selectZipFilePath,
        subtitle: selectZipFileDone
            ? const LinearProgressIndicator()
            : Text(zipFilePath),
        trailing: isSyncing
            ? const Icon(Icons.access_time_rounded)
            : IconButton(
                onPressed: isSyncing ? null : selectZipFilePath,
                icon: Icon(Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary)),
      ),
      SizedBox(
        height: 5,
        child: isSyncing ? const LinearProgressIndicator() : const Text(""),
      ),
      ListTile(
        trailing: const IconButton(onPressed: null, icon: Icon(Icons.delete)),
        title: const Text("内置词典(精简版)"),
        leading: Radio(
            value: 0,
            groupValue: defaultDictId,
            onChanged: (int? i) {
              if (i == null) return;
              handler.setDefaultDict(0);
              produceEvent(EventType.updateDict, 0);
              initDictInfos();
            }),
      ),
      const Divider(),
      Expanded(child: buildDictInfos())
    ];

    final body = Column(children: children);

    final appBar = AppBar(
      title: const Text("设置词典数据库"),
    );
    return getScaffold(
      context,
      appBar: appBar,
      body: body,
    );
  }
}

Future<RespData<void>> computeAddDictWithFile(
    Map<String, dynamic> param) async {
  String name = param['name']!;
  int fileSize = param['fileSize']!;
  Stream<List<int>> bytes = param['bytes']!;
  final dio = Dio();
  const www = "$debugHostOrigin/_addDictWithFile";
  // 分批发送 bytes
  var number = 0;
  final Queue<String> queue = Queue();
  final String fileUniqueId =
      "dict-$fileSize-${DateTime.now().millisecondsSinceEpoch}";
  var accumulative = 0;
  await for (List<int> v in bytes) {
    accumulative += v.length;
    number++;
    myPrint("v: ${v.length} number: $number");
    final seq = number;
    try {
      final Response<String> response = await dio.post(
        www,
        data: v,
        queryParameters: {
          "name": name,
          "seq": seq,
          "fileSize": fileSize,
          "fileUniqueId": fileUniqueId,
          "accumulative": accumulative
        },
        options: Options(
            responseType: ResponseType.plain,
            headers: {"Content-Type": "application/octet-stream"},
            validateStatus: (_) {
              return true;
            }),
      );
      if (response.statusCode != 200) {
        return RespData.err(response.data ?? "");
      }
    } catch (e) {
      myPrint(e);
      return RespData.err(e.toString());
    }
  }
  return RespData();
}
