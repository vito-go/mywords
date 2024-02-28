import 'dart:convert';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mywords/common/prefs/prefs.dart';
import '../libso/funcs.dart';
import '../libso/resp_data.dart';
import '../util/util.dart';


class NetProxy extends StatefulWidget {
  const NetProxy({super.key});

  @override
  State createState() {
    return _State();
  }
}

class _State extends State<NetProxy> {
  TextEditingController controllerPort = TextEditingController();
  TextEditingController controllerIP = TextEditingController();

  String netProxy = prefs.netProxy;

  String scheme = 'http';

  @override
  void initState() {
    super.initState();
    initController();
  }

  final defaultPort = 18964;
  final defaultCode = 890604;

  void initController() {
    final netProxy = prefs.netProxy;
    if (netProxy == '') return;
    final uri = Uri.tryParse(netProxy);
    if (uri == null) {
      prefs.netProxy = '';
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

  Widget dropButton() {
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

  Widget syncShareDataBuild() {
    return ElevatedButton.icon(
      onPressed: setNetProxy,
      icon: const Icon(Icons.save),
      label: const Text("保存"),
    );
  }

  Widget clearProxyButton() {
    return ElevatedButton.icon(
      onPressed: delNetProxy,
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
      decoration: const InputDecoration(
        labelText: "IP/域名",
        // border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  delNetProxy() {
    const netProxy = "";
    final netProxyC = netProxy.toNativeUtf8();
    final resultC = setProxyUrl(netProxyC);
    malloc.free(netProxyC);
    final RespData respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()) ?? {}, (json) => null);
    malloc.free(resultC);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    controllerIP.text = '';
    controllerPort.text = '';
    prefs.netProxy = '';
    myToast(context, "删除代理");
  }

  setNetProxy() {
    final netProxy = "$scheme://${controllerIP.text.trim()}:${controllerPort.text}";
    final netProxyC = netProxy.toNativeUtf8();
    final resultC = setProxyUrl(netProxyC);
    malloc.free(netProxyC);
    final RespData respData = RespData.fromJson(
        jsonDecode(resultC.toDartString()) ?? {}, (json) => null);
    malloc.free(resultC);
    if (respData.code != 0) {
      myToast(context, respData.message);
      return;
    }
    prefs.netProxy = netProxy;
    myToast(context, "设置代理成功！\n$netProxy");
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
          title: Row(
        children: [
          const Text("请选择协议"),
          const SizedBox(
            width: 20,
          ),
          dropButton(),
        ],
      )),
      ListTile(
        title: textFieldIP(),
      ),
      ListTile(
        title: textFieldPort(),
      ),
      const SizedBox(
        height: 20,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          syncShareDataBuild(),
          const SizedBox(
            width: 20,
          ),
          clearProxyButton(),
        ],
      )
    ];

    final body = Column(children: children);

    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("设置网络代理"),
    );
    return Scaffold(
      appBar: appBar,
      body: Padding(padding: const EdgeInsets.all(10), child: body),
    );
  }
}
