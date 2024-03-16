
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/global_event.dart';
import '../libso/funcs.dart';
import '../util/path.dart';
import '../util/util.dart';

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
      final p = file.path;
      if (p == null) {
        continue;
      }
      filePaths.add(p);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    defaultDownloadDir = getDefaultDownloadDir() ?? '';
  }

  Future<void> onTapParse() async {
    setState(() {
      isSyncing = true;
    });
    for (final p in filePaths) {
      final respData =
          await compute((message) => parseAndSaveArticleFromFile(message), p);
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

    myToast(context, "解析成功!");
    addToGlobalEvent(
        GlobalEvent(eventType: GlobalEventType.updateArticleList));
    return;
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
            leading = Icon(Icons.access_time_rounded, color: Colors.amber);
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

  Widget syncShareDataBuild() {
    return ElevatedButton.icon(
      onPressed: isSyncing ? null : onTapParse,
      icon: const Icon(Icons.group_work),
      label: const Text("开始解析"),
    );
  }

  Future<void> computeParse(String path) async {
    final respData = await compute(parseAndSaveArticleFromFile, path);
    if (respData.code != 0) {
      if (!context.mounted) return;
      myToast(context, respData.message);
      return;
    }
    addToGlobalEvent(
        GlobalEvent(eventType: GlobalEventType.updateArticleList));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
        title: const Text("选择文件"),
        leading: const Tooltip(
          message: "从本地选择html格式文章进行解析。长按文件可以进行多选",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info_outline),
        ),
        onTap: updateFilePaths,
        trailing: Icon(
          Icons.file_open,
          color: Theme.of(context).primaryColor,
        ),
      ),
      ListTile(
        trailing: syncShareDataBuild(),
        title: isSyncing ? const LinearProgressIndicator() : null,
        leading: const Tooltip(
          message: "暂仅支持html格式的文件。",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info),
        ),
      ),
    ];
    children.add(Expanded(child: buildFileList()));
    final col = Column(children: children);

    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("解析本地文章"),
    );
    return Scaffold(
      appBar: appBar,
      body: col,
    );
  }
}
