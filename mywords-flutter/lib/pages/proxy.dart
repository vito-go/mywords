import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mywords/libso/handler.dart';
import 'package:mywords/util/get_scaffold.dart';
import 'package:mywords/util/util.dart';

class NetProxy extends StatefulWidget {
  const NetProxy({super.key});

  @override
  State createState() {
    return _State();
  }
}

class _State extends State<NetProxy> {
  TextEditingController controllerPort = TextEditingController(text: " ");
  TextEditingController controllerIP = TextEditingController(text: " ");

  String scheme = 'http';

  @override
  void initState() {
    super.initState();
    initController();
  }

  final defaultPort = 18964;
  final defaultCode = 890604;

  void initController() async {
    final proxyURL = await handler.proxyURL();
    if (proxyURL == '') return;
    final uri = Uri.tryParse(proxyURL);
    if (uri == null) {
      // impossible wrong
      await handler.setProxyUrl("");
      return;
    }
    controllerIP.text = uri.host;
    controllerPort.text = uri.port.toString();
    scheme = uri.scheme;
  }

  @override
  void dispose() {
    super.dispose();
    controllerPort.dispose();
    controllerIP.dispose();
  }

  final schemeList = <String>["http", "socks5"];

  Widget get dropButton {
    return DropdownButton(
        value: scheme,
        items: const [
          DropdownMenuItem<String>(
            value: "http",
            child: Text("http"),
          ),
          DropdownMenuItem<String>(
            value: "socks5",
            child: Text("socks5"),
          ),
        ],
        onChanged: (v) {
          if (v == null) return;
          scheme = v;
          setState(() {});
        });
  }

  Widget get saveProxyButton {
    return ElevatedButton.icon(
      onPressed: () async {
        final host = controllerIP.text.trim();
        if (host.isEmpty) {
          myToast(context, "ip/域名不能为空");
          return;
        }
        final port = controllerPort.text.trim();
        if (port.isEmpty) {
          myToast(context, "端口号不能为空");
          return;
        }
        final netProxy = "$scheme://$host:$port";
        final respData = await handler.setProxyUrl(netProxy);
        if (respData.code != 0) {
          myToast(context, respData.message);
          return;
        }
        myToast(context, "设置代理成功！\n$netProxy");
      },
      icon: const Icon(Icons.save),
      label: const Text("保存"),
    );
  }

  Widget get delProxyButton {
    return ElevatedButton.icon(
      onPressed: () async {
        await handler.setProxyUrl("");
        controllerIP.text = '';
        controllerPort.text = '';
        myToast(context, "删除代理");
      },
      icon: const Icon(
        Icons.clear,
        color: Colors.red,
      ),
      label: const Text("删除"),
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
      decoration: const InputDecoration(labelText: "IP/域名"),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
          title: Row(
        children: [
          const Text("请选择协议"),
          const SizedBox(width: 20),
          dropButton,
        ],
      )),
      ListTile(title: textFieldIP()),
      ListTile(title: textFieldPort()),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          saveProxyButton,
          const SizedBox(width: 20),
          delProxyButton,
        ],
      )
    ];

    final body = ListView(children: children);
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("设置网络代理"),
    );
    return getScaffold(
      context,
      appBar: appBar,
      body: body,
    );
  }
}
