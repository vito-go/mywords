import 'package:flutter/material.dart';
import 'package:mywords/libso/handler.dart';

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
    ips.clear();
    ips = await handler.getIPv4s() ?? [];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateIP();
  }

  Widget _buildListTileIP() {
    const title = Text("本机IP");
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
      trailing:
          IconButton(onPressed: updateIP, icon: const Icon(Icons.refresh)),
    );
    return listTile;
  }

  @override
  Widget build(BuildContext context) {
    return _buildListTileIP();
  }
}
