import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mywords/common/queue.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/path.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/widgets/private_ip.dart';

import 'package:mywords/environment.dart';

class RestoreData extends StatefulWidget {
  const RestoreData({super.key});

  @override
  State createState() {
    return _RestoreDataState();
  }
}

class _RestoreDataState extends State<RestoreData> {
  TextEditingController controllerPort = TextEditingController();
  TextEditingController controllerIP = TextEditingController();
  TextEditingController controllerCode = TextEditingController();

  String defaultDownloadDir = '';

  @override
  void initState() {
    super.initState();
    defaultDownloadDir = getDefaultDownloadDir() ?? '';
    initController();
  }

  final defaultPort = 18964;
  final defaultCode = 890604;

  void initController() {
    final ss = prefs.syncIpPortCode;
    myPrint(ss);
    if (ss.length != 3) {
      controllerPort.text = '$defaultPort';
      controllerCode.text = '$defaultCode';
      return;
    }
    final ip = ss[0];
    final p = int.tryParse(ss[1]);
    final c = int.tryParse(ss[2]);
    if (p != null && c != null) {
      controllerIP.text = ip;
      controllerPort.text = p.toString();
      controllerCode.text = c.toString();
    } else {
      controllerPort.text = '$defaultPort';
      controllerCode.text = '$defaultCode';
      controllerIP.text = '';
    }
  }

  @override
  void dispose() {
    super.dispose();
    controllerPort.dispose();
    controllerCode.dispose();
    controllerIP.dispose();
  }

  Future<int> syncShareData() async {
    if (controllerIP.text == "") {
      myToast(context, "IP/域名不能为空");
      return -1;
    }
    if (controllerPort.text == "") {
      myToast(context, "端口号不能为空");
      return -1;
    }
    if (controllerCode.text == "") {
      myToast(context, "Code码不能为空");
      return -1;
    }
    setState(() {
      isSyncing = true;
    });
    final port = int.parse(controllerPort.text);
    final code = int.parse(controllerCode.text);
    String tempDir = "";
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      tempDir = dir.path;
    }

    final respData =
        await compute(computeRestoreFromShareServer, <String, dynamic>{
      'ip': controllerIP.text,
      'port': port,
      'code': code,
      'tempDir': tempDir,
      'syncKnownWords': syncKnownWords,
      'syncToadyWordCount': syncToadyWordCount,
    });
    setState(() {
      isSyncing = false;
    });

    if (respData.code != 0) {
      myToast(context, respData.message);
      return -1;
    }
    prefs.syncIpPortCode = [
      controllerIP.text,
      controllerPort.text,
      controllerCode.text
    ];
    myToast(context, "同步成功!");
    produceEvent(EventType.syncData, syncToadyWordCount);
    return 0;
  }

  bool isSyncing = false;
  bool isSyncingKnownWords = false;
  bool isSyncFileInfos = false;

  void restoreFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        initialDirectory: getDefaultDownloadDir(),
        allowMultiple: false,
        withReadStream: kIsWeb,
        type: FileType.custom,
        allowedExtensions: ["zip"]);
    if (result == null) {
      return;
    }
    final files = result.files;
    if (files.isEmpty) {
      return;
    }
    final file = files[0];
    final p = kIsWeb ? file.name : file.path;
    if (p == null) {
      return;
    }
    setState(() {
      isSyncing = true;
    });

    final RespData<void> respData;
    if (!kIsWeb) {
      if (file.readStream == null) {
        myToast(context, 'null stream: $p');
        return;
      }
      respData = await compute(computeRestoreFromBackUpData, <String, dynamic>{
        "syncKnownWords": syncKnownWords,
        "zipPath": file.path!,
        "syncToadyWordCount": syncToadyWordCount,
      });
    } else {
      respData =
          await compute(computeWebRestoreFromBackUpData, <String, dynamic>{
        "syncKnownWords": syncKnownWords,
        "bytes": file.readStream,
        "syncToadyWordCount": syncToadyWordCount,
      });
    }
    setState(() {
      isSyncing = false;
    });
    if (respData.code != 0) {
      myToast(context, "恢复失败!\n${respData.message}");
      return;
    }
    myToast(context, "恢复完成");
    produceEvent(EventType.updateArticleList);
  }

  Widget textFieldCode() {
    return TextField(
      keyboardType: TextInputType.number,
      controller: controllerCode,
      decoration: const InputDecoration(
        labelText: "Code码",
        isDense: true,
      ),
      inputFormatters: [
        LengthLimitingTextInputFormatter(6),
        FilteringTextInputFormatter(RegExp("[0-9]"), allow: true)
      ],
    );
  }

  Widget textFieldPort() {
    return TextField(
      controller: controllerPort,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: "端口",
        isDense: true,
      ),
      inputFormatters: [
        LengthLimitingTextInputFormatter(5),
        FilteringTextInputFormatter(RegExp("[0-9]"), allow: true)
      ],
    );
  }

  Widget textFieldIP() {
    return TextField(
      controller: controllerIP,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: "IP/域名",
        // border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  bool syncToadyWordCount = prefs.syncToadyWordCount;
  bool syncKnownWords = prefs.syncKnownWords;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      const PrivateIP(),
    ];
    children.add(ListTile(title: textFieldIP()));
    children.add(Row(
      children: [
        Flexible(child: ListTile(title: textFieldPort())),
        Flexible(child: ListTile(title: textFieldCode())),
      ],
    ));

    children.addAll([
      ListTile(
        title: const Text("我的单词库"),
        leading: const Tooltip(
          message: "我的单词库同步后, 学习统计也将同步与本地数据合并",
          triggerMode: TooltipTriggerMode.tap,
          showDuration: Duration(seconds: 15),
          child: Icon(Icons.info_outline),
        ),
        trailing: IconButton(
            onPressed: isSyncingKnownWords
                ? null
                : () async {
                    prefs.syncIpPortCode = [
                      controllerIP.text.trim(),
                      controllerPort.text.trim(),
                      controllerCode.text.trim(),
                    ];
                    setState(() {
                      isSyncingKnownWords = true;
                    });
                    final respData = await compute((param) {
                      return handler.syncData(
                          param['ip'] as String,
                          param['port'] as int,
                          param['code'] as int,
                          param['syncKind'] as int);
                    }, <String, dynamic>{
                      'ip': controllerIP.text.trim(),
                      'port': int.parse(controllerPort.text.trim()),
                      'code': int.parse(controllerCode.text.trim()),
                      'syncKind': 1
                    });

                    setState(() {
                      isSyncingKnownWords = false;
                    });
                    if (respData.code != 0) {
                      myToast(context, respData.message);
                      return;
                    }
                    myToast(context, "同步我的单词库成功");
                    produceEvent(EventType.updateKnownWord);
                  },
            icon: const Icon(Icons.sync)),
        subtitle: isSyncingKnownWords
            ? const LinearProgressIndicator()
            : const Text(""),
      ),
      ListTile(
        title: const Text("同步文章信息"),
        leading: const Tooltip(
          message: "同步数据后，本地数据将与远程数据进行合并",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info_outline),
        ),
        subtitle:
            isSyncFileInfos ? const LinearProgressIndicator() : const Text(""),
        trailing: IconButton(
            onPressed: isSyncFileInfos
                ? null
                : () async {
                    prefs.syncIpPortCode = [
                      controllerIP.text.trim(),
                      controllerPort.text.trim(),
                      controllerCode.text.trim(),
                    ];
                    setState(() {
                      isSyncFileInfos = true;
                    });

                    final respData = await compute((param) {
                      return handler.syncData(
                          param['ip'] as String,
                          param['port'] as int,
                          param['code'] as int,
                          param['syncKind'] as int);
                    }, <String, dynamic>{
                      'ip': controllerIP.text.trim(),
                      'port': int.parse(controllerPort.text.trim()),
                      'code': int.parse(controllerCode.text.trim()),
                      'syncKind': 2
                    });
                    setState(() {
                      isSyncFileInfos = false;
                    });
                    if (respData.code != 0) {
                      myToast(context, respData.message);
                      return;
                    }
                    myToast(context, "同步文章信息成功");
                    produceEvent(EventType.updateArticleList);
                  },
            icon: const Icon(Icons.sync)),
      ),
    ]);

    final col = ListView(children: children);

    final appBar = AppBar(
      title: const Text("同步数据"),
    );
    return getScaffold(
      context,
      appBar: appBar,
      body: col,
    );
  }
}

Future<RespData<void>> computeRestoreFromShareServer(
    Map<String, dynamic> param) async {
  final ip = param['ip'] as String;
  final port = param['port'] as int;
  final code = param['code'] as int;
  final tempDir = param['tempDir'] as String;
  final syncToadyWordCount = param['syncToadyWordCount'] as bool;
  final syncKnownWords = param['syncKnownWords'] as bool;
  final syncByRemoteArchived = param['syncByRemoteArchived'] as bool;
  return handler.restoreFromShareServer(ip, port, code, syncKnownWords, tempDir,
      syncToadyWordCount, syncByRemoteArchived);
}

// bool syncKnownWords,
// String zipPath,
// bool syncToadyWordCount,
Future<RespData<void>> computeRestoreFromBackUpData(
    Map<String, dynamic> param) async {
  final zipPath = param['zipPath'] as String;
  final syncToadyWordCount = param['syncToadyWordCount'] as bool;
  final syncKnownWords = param['syncKnownWords'] as bool;
  final syncByRemoteArchived = param['syncByRemoteArchived'] as bool;
  return handler.restoreFromBackUpData(
      syncKnownWords, zipPath, syncToadyWordCount, syncByRemoteArchived);
}

Future<RespData<void>> computeWebRestoreFromBackUpData(
    Map<String, dynamic> param) async {
  Stream<List<int>> bytes = param['bytes']!;
  final syncToadyWordCount = param['syncToadyWordCount'] as bool;
  final syncKnownWords = param['syncKnownWords'] as bool;
  final syncByRemoteArchived = param['syncByRemoteArchived'] as bool;

  final dio = Dio();
  const www = "$debugHostOrigin/_webRestoreFromBackUpData";
  try {
    final Response<String> response = await dio.post(
      www,
      data: bytes,
      queryParameters: {
        "syncToadyWordCount": syncToadyWordCount,
        "syncKnownWords": syncKnownWords,
        "syncByRemoteArchived": syncByRemoteArchived,
      },
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
