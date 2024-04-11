import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/widgets/stream_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mywords/widgets/private_ip.dart';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/util.dart';

import '../libso/types.dart';

class SyncData extends StatefulWidget {
  const SyncData({super.key});

  @override
  State createState() {
    return _SyncDataState();
  }
}

class _SyncDataState extends State<SyncData> {
  ShareInfo shareInfo = ShareInfo(port: 18964, code: 890604, open: false);
  TextEditingController controllerPort = TextEditingController(text: " ");
  TextEditingController controllerCode = TextEditingController(text: " ");
  TextEditingController controllerBackUpZipName =
      TextEditingController(text: "mywords-backup-data");

  @override
  void initState() {
    super.initState();
    initController();
    updateLocalExampleIP();
  }

  void updateLocalExampleIP() async {
    final ips = await handler.getIPv4s();
    if (ips == null) return;
    if (ips.isEmpty) return;
    localExampleIP = ips.last;
    setState(() {});
  }

  void initController() async {
    shareInfo = await handler.getShareInfo();
    controllerPort.text = '${shareInfo.port}';
    controllerCode.text = '${shareInfo.code}';
    setState(() {});
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
                    final zipName = "${controllerBackUpZipName.text}.zip";
                    final dirPath = await dataDirPath();
                    final respData =
                        await compute(computeBackUpData, <String, String>{
                      "zipName": zipName,
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

  Future<void> doShareClose() async {
    final respData = await handler.shareClosed();
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    shareInfo.open = false;
    setState(() {});
    handler.println("share server closed!");
    return;
  }

  Future<void> doShareOpen() async {
    if (controllerPort.text.trim() == "") {
      myToast(context, "端口号不能为空");
      return;
    }
    if (controllerCode.text.trim() == "") {
      myToast(context, "Code码不能为空");
      return;
    }
    final port = int.parse(controllerPort.text.trim());
    final code = int.parse(controllerCode.text.trim());
    final respData = await handler.shareOpen(port, code);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    shareInfo.open = true;
    shareInfo.port = port;
    shareInfo.code = code;
    setState(() {});
    return;
  }

  Widget switchBuild() {
    return Switch(
        value: shareInfo.open,
        onChanged: (v) async {
          if (v) {
            doShareOpen();
          } else {
            doShareClose();
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
            "开启后将允许其他设备访问进行同步本机数据，也可以在浏览器中进行下载 http://ip:port/code,\n例如 http://$localExampleIP:${shareInfo.port}/${shareInfo.port}",
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

    return getScaffold(
      context,
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
