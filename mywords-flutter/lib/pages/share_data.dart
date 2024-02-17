import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/log.dart';
import 'package:mywords/util/net.dart';
import 'package:mywords/widgets/stream_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../libso/funcs.dart';
import '../util/path.dart';
import '../util/util.dart';
import '../widgets/private_ip.dart';

class SyncData extends StatefulWidget {
  const SyncData({super.key});

  @override
  State createState() {
    return _SyncDataState();
  }
}

class _SyncDataState extends State<SyncData> {
  bool shareOpenOK = false;
  TextEditingController controllerPort = TextEditingController();
  TextEditingController controllerCode = TextEditingController();
  TextEditingController controllerBackUpZipName =
      TextEditingController(text: "mywords-backupdata");
  String defaultDownloadDir = '';

  @override
  void initState() {
    super.initState();
    defaultDownloadDir = getDefaultDownloadDir() ?? '';
    initController();
    getIPv4s().then((value) {
      if (value.isNotEmpty) {
        setState(() {
          localExampleIP = value.last;
        });
      }
    });
  }

  final defaultPort = 18964;
  final defaultCode = 890604;

  void initController() {
    final ss = prefs.shareOpenPortCode.split("/");
    myPrint(ss);
    if (ss.length != 2) {
      controllerPort.text = '$defaultPort';
      controllerCode.text = '$defaultCode';
      return;
    }
    myPrint(ss);
    final p = int.tryParse(ss[0]);
    final c = int.tryParse(ss[1]);
    if (p != null && c != null) {
      controllerPort.text = p.toString();
      controllerCode.text = c.toString();
      shareOpenOK = true;
    } else {
      controllerPort.text = '$defaultPort';
      controllerCode.text = '$defaultCode';
    }
  }

  @override
  void dispose() {
    super.dispose();
    controllerPort.dispose();
    controllerCode.dispose();
    controllerBackUpZipName.dispose();
  }

  Future<String> dataDirPath() async {
    final dir = await getApplicationSupportDirectory();
    return path.join(dir.path, "data");
  }

  void _onTapBackUpData() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("备份数据到下载目录"),
            content: TextField(
                controller: controllerBackUpZipName,
                decoration: const InputDecoration(
                    hintText: "请输入备份文件名字", suffix: Text(".zip"))),
            actions: [
              TextButton(
                  onPressed: () async {
                    if (controllerBackUpZipName.text == "") {
                      myToast(context, "文件名不能为空");
                      return;
                    }
                    if (controllerBackUpZipName.text.startsWith("..")) {
                      myToast(context, "文件名不能以..开头");
                    }
                    if (controllerBackUpZipName.text.startsWith("/")) {
                      myToast(context, "文件名不能包含特殊字符/");
                    }
                    final dirPath = await dataDirPath();
                    final respData = await compute(
                        (message) => backUpData(message), <String, String>{
                      "zipName": controllerBackUpZipName.text,
                      "dataDirPath": dirPath,
                    });
                    if (respData.code != 0) {
                      myToast(context, "备份失败!\n${respData.message}");
                      return;
                    }
                    myToast(context, "备份成功!\n${respData.data}");
                    Navigator.pop(context);
                  },
                  child: const Text("保存")),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消"))
            ],
          );
        });
    if (!context.mounted) {
      return;
    }
  }

  int doShareClose() {
    final respData = shareClosed();
    if (respData.code != 0) {
      myToast(context, respData.message);
      return -1;
    }
    prefs.shareOpenPortCode = '';
    println("share server closed!");

    return 0;
  }

  int doShareOpen() {
    if (controllerPort.text == "") {
      myToast(context, "端口号不能为空");
      return -1;
    }
    if (controllerCode.text == "") {
      myToast(context, "Code码不能为空");
      return -1;
    }
    final port = int.parse(controllerPort.text);
    final code = int.parse(controllerCode.text);
    final respData = shareOpen(port, code);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return -1;
    }
    prefs.shareOpenPortCode = '$port/$code';
    return 0;
  }

  Widget switchBuild() {
    return Switch(
        value: shareOpenOK,
        onChanged: (v) {
          int c;
          if (v) {
            c = doShareOpen();
          } else {
            c = doShareClose();
          }
          if (c == 0) {
            shareOpenOK = v;
            setState(() {});
          }
        });
  }

  String localExampleIP = "192.168.89.64";

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      const PrivateIP(),
      ListTile(
        title: const Text("备份数据"),
        leading: Tooltip(
          message: "备份文件将保存在: $defaultDownloadDir",
          triggerMode: TooltipTriggerMode.tap,
          child: const Icon(Icons.info_outline),
        ),
        trailing: IconButton(
          onPressed: _onTapBackUpData,
          icon: Icon(
            Icons.save_alt,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      ListTile(
        leading: Tooltip(
          message:
              "开启后将允许其他设备进行访问进行同步本机数据，也可以在浏览器中进行下载 http://ip:port/code,\n例如 http://$localExampleIP:${prefs.shareOpenPortCode == '' ? '$defaultPort/$defaultCode' : prefs.shareOpenPortCode}",
          triggerMode: TooltipTriggerMode.tap,
          child: const Icon(Icons.info_outline),
        ),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllerPort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "端口",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(5),
                  FilteringTextInputFormatter(RegExp("[0-9]"), allow: true)
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                controller: controllerCode,
                decoration: const InputDecoration(
                  labelText: "Code码",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                  FilteringTextInputFormatter(RegExp("[0-9]"), allow: true)
                ],
              ),
            ),
          ],
        ),
        trailing: switchBuild(),
      ),
    ];

    children.add(const Flexible(child: StreamLog(maxLines: 200)));
    final body = Column(
      children: children,
    );
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("分享/备份数据"),
    );

    return Scaffold(
      appBar: appBar,
      body: Padding(padding: const EdgeInsets.all(10), child: body),
    );
  }
}
