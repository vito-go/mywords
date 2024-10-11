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
  TextEditingController controllerPort = TextEditingController(text: "");
  TextEditingController controllerIP = TextEditingController(text: "");
  TextEditingController controllerUsername = TextEditingController(text: "");
  TextEditingController controllerPassword = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final proxyURL = await handler.proxyURL();
    if (proxyURL == '') return;
    final uri = Uri.tryParse(proxyURL);
    if (uri == null) {
      // impossible to reach here
      await handler.delProxy();
      return;
    }
    controllerIP.text = uri.host;
    controllerPort.text = uri.port.toString();
    if (uri.userInfo.split(":").length == 2) {
      controllerUsername.text = uri.userInfo.split(":")[0];
      controllerPassword.text = uri.userInfo.split(":")[1];
    }
    scheme = uri.scheme;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    controllerPort.dispose();
    controllerIP.dispose();
    controllerUsername.dispose();
    controllerPassword.dispose();
  }

  final schemeList = <String>["socks5", "http", "https"];
  String scheme = 'socks5';

  Widget get dropButton {
    return DropdownButton(
        value: scheme,
        items: schemeList.map((e) {
          return DropdownMenuItem<String>(
            value: e,
            child: Text(e),
          );
        }).toList(),
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
          myToast(context, "IP/domain name cannot be empty");
          return;
        }
        final port = controllerPort.text.trim();
        if (port.isEmpty) {
          myToast(context, "Port number cannot be empty");
          return;
        }
        final username = controllerUsername.text.trim();
        final password = controllerPassword.text.trim();
        String netProxy = "$scheme://$username:$password@$host:$port";
        if (username.isEmpty) {
          netProxy = "$scheme://$host:$port";
        }
        final respData = await handler.setProxyUrl(netProxy);
        if (respData.code != 0) {
          myToast(context, respData.message);
          return;
        }
        unFocus();
        myToast(context, "Set proxy successfully!\n$netProxy");
      },
      icon: const Icon(Icons.save),
      label: const Text("Save"),
    );
  }

  Widget get delProxyButton {
    return ElevatedButton.icon(
      onPressed: () async {
        await handler.delProxy();
        unFocus();
        controllerIP.text = '';
        controllerPort.text = '';
        controllerUsername.text = '';
        controllerPassword.text = '';
        myToast(context, "Delete proxy successfully!");
      },
      icon: const Icon(
        Icons.clear,
        color: Colors.red,
      ),
      label: const Text("Delete"),
    );
  }

  Widget textFieldPort() {
    return TextField(
      controller: controllerPort,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: "Port",
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
      decoration: const InputDecoration(labelText: "IP/domain name"),
    );
  }

  Widget textFieldUsername() {
    return TextField(
      controller: controllerUsername,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(labelText: "Username (optional)"),
    );
  }

  Widget textFieldPassword() {
    return TextField(
      controller: controllerPassword,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(labelText: "Password (optional)"),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
          title: Row(children: [
        // const Text("请选择协议"),
        const Text("Select protocol"),
        const SizedBox(width: 20),
        dropButton,
      ])),
      ListTile(title: textFieldIP()),
      ListTile(title: textFieldPort()),
      ListTile(title: textFieldUsername()),
      ListTile(title: textFieldPassword()),
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
      title: const Text("Network Proxy"),
    );
    return getScaffold(
      context,
      appBar: appBar,
      body: body,
    );
  }
}
