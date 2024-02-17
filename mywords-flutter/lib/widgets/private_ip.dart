import 'dart:io';

 import 'package:flutter/material.dart';

import '../libso/log.dart';

class PrivateIP extends StatefulWidget {
  const PrivateIP({super.key});

  @override
  State<StatefulWidget> createState() {
    return PrivateIPState();
  }
}

class PrivateIPState extends State {
  List<String> ips = [];

  void updateIP() async {
    final networks =
        await NetworkInterface.list(type: InternetAddressType.IPv4);
    ips.clear();
    for (var ele in networks) {
      for (var e in ele.addresses) {
        ips.add(e.address);
      }
    }
    println("local ip: $ips");
    ips.sort((a, b) => a.length.compareTo(b.length));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateIP();
  }

  Widget _buildListTileIP() {
    Widget title;
    if (ips.isEmpty) {
      title = TextButton.icon(
          onPressed: updateIP,
          icon: const Icon(Icons.refresh),
          label: const Text("No internet connection"));
    } else {
      title = const Text("本机IP");
    }
    ListTile listTile = ListTile(
      title: title,
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: SingleChildScrollView(
                          child: Column(
                        children: ips.map((e) => SelectableText(e)).toList(),
                      ))));
            });
      },
      subtitle: Text(
        ips.join(", "),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(onPressed: updateIP, icon: const Icon(Icons.refresh)),
    );
    return listTile;
  }

  @override
  Widget build(BuildContext context) {
    return _buildListTileIP();
  }
}
