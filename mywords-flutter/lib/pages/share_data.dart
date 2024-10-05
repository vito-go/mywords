import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mywords/libso/handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mywords/widgets/private_ip.dart';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/util.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
    updateShareInfo();
    updateLocalExampleIP();
  }

  void updateLocalExampleIP() async {
    final ips = await handler.getIPv4s();
    if (ips == null) return;
    if (ips.isEmpty) return;
    localExampleIP = ips.last;
    setState(() {});
  }

  void updateShareInfo() async {
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

  Future<void> doShareClose() async {
    final respData = await handler.shareClosed(
      int.tryParse(controllerPort.text.trim()) ?? 0,
      int.tryParse(controllerCode.text.trim()) ?? 0,
    );
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    updateShareInfo();
    return;
  }

  Future<void> doShareOpen() async {
    if (controllerPort.text.trim() == "") {
      // myToast(context, "端口号不能为空");
      myToast(context, "Port number cannot be empty");
      return;
    }
    if (controllerCode.text.trim() == "") {
      // myToast(context, "Code码不能为空");
      myToast(context, "Auth Code cannot be empty");
      return;
    }
    final port = int.parse(controllerPort.text.trim());
    final code = int.parse(controllerCode.text.trim());
    final respData = await handler.shareOpen(port, code);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    updateShareInfo();
    return;
  }

  Widget switchBuild() {
    return Switch(
        value: shareInfo.open,
        onChanged: (v) async {
          unFocus();
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
      leading: Tooltip(
        // message:            "开启后将允许其他设备访问进行同步本机数据，也可以在浏览器中进行下载 http://ip:port/code,\n例如 http://$localExampleIP:${shareInfo.port}/${shareInfo.port}",
        message:
            "After opening, other devices will be allowed to access and synchronize local data, and you can also download it in the browser http://ip:port/code,\nfor example http://$localExampleIP:${shareInfo.port}/${shareInfo.port}",
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 30),
        child: const Icon(Icons.info_outline),
      ),
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controllerPort,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                // labelText: "端口",
                labelText: "Port",
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
                // labelText: "Code码",// auth
                labelText: "Auth Code",
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
    if (shareInfo.open) {
      final shareFileInfosURL =
          "http://127.0.0.1:${shareInfo.port}/share/shareFileInfos?code=${shareInfo.code}";

      children.add(ListTile(
        title: const Text("文件列表"),
        leading: const Icon(Icons.http),
        subtitle: Text(shareFileInfosURL),
        trailing: IconButton(
            onPressed: () {
              launchUrlString(shareFileInfosURL);
            },
            icon: const Icon(Icons.open_in_browser)),
      ));

      final shareKnownWordsURL =
          "http://127.0.0.1:${shareInfo.port}/share/shareKnownWords?code=${shareInfo.code}";
      children.add(ListTile(
        leading: const Icon(Icons.http),
        title: const Text("Known Words"),
        subtitle: Text(shareKnownWordsURL),
        trailing: IconButton(
            onPressed: () {
              launchUrlString(shareKnownWordsURL);
            },
            icon: const Icon(Icons.open_in_browser)),
      ));
    }
    final body = Column(children: children);
    final appBar = AppBar(
      title: const Text("Share Data"),
    );
    return getScaffold(
      context,
      appBar: appBar,
      body: Padding(padding: const EdgeInsets.all(10), child: body),
    );
  }
}
