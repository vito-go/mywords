import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';
import 'package:mywords/widgets/stream_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mywords/widgets/private_ip.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/util.dart';

import 'package:mywords/environment.dart';

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

  @override
  void initState() {
    super.initState();
    updateLocalExampleIP();
    initController();
  }

  final defaultPort = 18964;
  final defaultCode = 890604;

  void updateLocalExampleIP() async {
    final ips = await handler.getIPv4s();
    if (ips == null) return;
    if (ips.isEmpty) return;
    localExampleIP = ips.last;
    setState(() {});
  }

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

                    if (kIsWeb) {
                      Navigator.pop(context);
                      downloadBackUpdate("${controllerBackUpZipName.text}.zip");
                      return;
                    }

                    final dirPath = await dataDirPath();
                    final respData = await compute(
                        (message) => computeBackUpData(message),
                        <String, String>{
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

  Future<int> doShareClose() async {
    final respData = await handler.shareClosed();
    if (respData.code != 0) {
      myToast(context, respData.message);
      return -1;
    }
    prefs.shareOpenPortCode = '';
    handler.println("share server closed!");

    return 0;
  }

  Future<int> doShareOpen() async {
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
    final respData = await handler.shareOpen(port, code);
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
        onChanged: (v) async {
          int c;
          if (v) {
            c = await doShareOpen();
          } else {
            c = await doShareClose();
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
    List<Widget> children = [const PrivateIP()];
    children.add(ListTile(
      title: const Text("备份数据"),
      leading: const Tooltip(
        message: "学习数据备份文件将保存在本地",
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(Icons.info_outline),
      ),
      trailing: IconButton(
        onPressed: _onTapBackUpData,
        icon: Icon(
          Icons.save_alt,
          color: Theme.of(context).primaryColor,
        ),
      ),
    ));
    children.add(ListTile(
      leading: Tooltip(
        message:
            "开启后将允许其他设备访问进行同步本机数据，也可以在浏览器中进行下载 http://ip:port/code,\n例如 http://$localExampleIP:${prefs.shareOpenPortCode == '' ? '$defaultPort/$defaultCode' : prefs.shareOpenPortCode}",
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
    ));
    if (!kIsWeb) {
      children.add(const Flexible(child: StreamLog(maxLines: 200)));
    }
    final body = Column(children: children);
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("分享/备份数据"),
    );

    return getScaffold(context,
      appBar: appBar,
      body: Padding(padding: const EdgeInsets.all(10), child: body),
    );
  }
}

Future<RespData<String>> computeBackUpData(Map<String, String> param) async {
  final String zipName = param['zipName']!;
  final String dataDirPath = param['dataDirPath']!;
  return handler.backUpData(zipName, dataDirPath);
}

void downloadBackUpdate(String zipFileName) async {
  final www = "$debugHostOrigin/_downloadBackUpdate?name=$zipFileName";
  launchUrlString(www);
  return;
}
