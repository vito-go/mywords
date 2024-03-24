import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/global_event.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';

import 'package:mywords/environment.dart';
import 'package:mywords/libso/debug_host_origin.dart';
import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/path.dart';
import 'package:mywords/util/util.dart';

class ParseLocalFile extends StatefulWidget {
  const ParseLocalFile({super.key});

  @override
  State createState() {
    return _State();
  }
}

class _State extends State<ParseLocalFile> {
  List<String> filePaths = [];
  String defaultDownloadDir = '';
  Map<String, String> filePathMap =
      {}; // null: wait,'': success, not empty: error

  void updateFilePaths() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        initialDirectory: getDefaultDownloadDir(),
        allowMultiple: true,
        withReadStream: true,
        type: FileType.custom,
        allowedExtensions: ["html"]);
    if (result == null) {
      return;
    }
    final files = result.files;
    if (files.isEmpty) {
      return;
    }
    filePaths.clear();
    for (final file in files) {
      final p = kIsWeb ? file.name : file.path;
      if (p == null) {
        continue;
      }
      filePaths.add(p);
    }
    setState(() {
      isSyncing = true;
    });
    for (final file in files) {
      final p = kIsWeb ? file.name : file.path;
      if (p == null) {
        continue;
      }
      final RespData<void> respData;
      if (kIsWeb) {
        if (file.readStream == null) {
          filePathMap[p] = 'null stream';
          continue;
        }
        respData = await compute(
            (message) => computeWebParseAndSaveArticleFromFile(message),
            {"name": file.name, "bytes": file.readStream!});
      } else {
        respData = await compute(
            (message) => computeParseAndSaveArticleFromFile(message), p);
      }
      if (respData.code == 0) {
        filePathMap[p] = '';
      } else {
        filePathMap[p] = respData.message;
      }
      setState(() {});
    }
    setState(() {
      isSyncing = false;
    });
    myToast(context, "解析完成!");
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateArticleList));
    return;
  }

  @override
  void initState() {
    super.initState();
    defaultDownloadDir = getDefaultDownloadDir() ?? '';
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildFileList() {
    return ListView.separated(
        itemBuilder: (BuildContext context, int idx) {
          final p = filePaths[idx];
          final errMsg = filePathMap[p];
          Widget leading;
          if (errMsg == null) {
            leading =
                const Icon(Icons.access_time_rounded, color: Colors.amber);
          } else if (errMsg == '') {
            leading = const Icon(
              Icons.done_all,
              color: Colors.green,
            );
          } else {
            leading = Tooltip(
                message: errMsg,
                child: leading = const Icon(
                  Icons.error,
                  color: Colors.red,
                ));
          }
          return ListTile(
            leading: leading,
            title: Text(filePaths[idx]),
          );
        },
        separatorBuilder: (BuildContext context, int idx) {
          return const Divider();
        },
        itemCount: filePaths.length);
  }

  bool isSyncing = false;

  Future<void> computeParse(String path) async {
    final respData = await compute(computeParseAndSaveArticleFromFile, path);
    if (respData.code != 0) {
      if (!context.mounted) return;
      myToast(context, respData.message);
      return;
    }
    addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateArticleList));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
        title: const Text("选择文件"),
        leading: const Tooltip(
          message: "从本地选择html格式文章进行解析，支持多选文件",
          showDuration:Duration(seconds: 10),
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info_outline),
        ),
        onTap: updateFilePaths,
        trailing: Icon(
          Icons.file_open,
          color: Theme.of(context).primaryColor,
        ),
      ),
      SizedBox(
        height: 5,
        child: isSyncing ? const LinearProgressIndicator() : const Text(""),
      ),
    ];
    children.add(Expanded(child: buildFileList()));
    final col = Column(children: children);

    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("解析本地文章"),
    );
    return getScaffold(context,
      appBar: appBar,
      body: col,
    );
  }
}

Future<RespData<void>> computeParseAndSaveArticleFromFile(String path) async {
  return handler.parseAndSaveArticleFromFile(path);
}

Future<RespData<void>> computeWebParseAndSaveArticleFromFile(
    Map<String, dynamic> param) async {
  String name = param['name']!;
  Stream<List<int>> bytes = param['bytes']!;
  final dio = Dio();
  const www = "$debugHostOrigin/_webParseAndSaveArticleFromFile";
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
