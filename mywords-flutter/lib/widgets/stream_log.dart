import 'dart:convert';
import 'dart:math';
import 'package:mywords/libso/handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';


class StreamLog extends StatefulWidget {
  const StreamLog({super.key, required this.maxLines});

  final int maxLines;

  @override
  State createState() {
    return StreamLogState();
  }
}

class StreamLogState extends State<StreamLog> {
  List<String> logs = [];
  late final maxLines = widget.maxLines;
  bool autoScroll = true;

  void controllerListen() {
    // 判断是否向上滑动
    if (controller.position.userScrollDirection == ScrollDirection.forward) {
      if (!autoScroll) {
        return;
      }
      setState(() {
        autoScroll = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initHttpServer();
    controller.addListener(controllerListen);
  }

  void parseReq(HttpRequest req) async {
    final xLogNonce = req.headers.value("X-Log-Nonce");
    if (xLogNonce != logNonce) {
      req.response.statusCode = 403;
      req.response.close();
      handler.println("ERROR request log. X-Log-Nonce error: $xLogNonce");
      return;
    }
    if (!open) {
      req.response.write("ok");
      req.response.close();
      return;
    }
    final bodyStr = await utf8.decodeStream(req);
    req.response.write("ok");
    req.response.close();
    updateLog(bodyStr.trim());
  }

  HttpServer? httpServer;

  void initHttpServer() async {
    final value =
        await HttpServer.bind(InternetAddress.anyIPv4, 0, shared: true);
    value.listen(parseReq, onError: (e) {
      debugPrint(e.toString());
      value.close();
    }, onDone: () {
      debugPrint("http on done");
    });
    final sec = Random.secure();
    logNonce = base64Encode(List<int>.generate(16, (_) {
      return sec.nextInt(256);
    }));
    logUrl = "http://127.0.0.1:${value.port}";
    debugPrint("设置http log url: $logUrl, logNonce: $logNonce");
    handler.setLogUrl(logUrl, logNonce);
    httpServer = value;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    httpServer?.close(force: true);
  }

  void updateLog(String text) {
    if (logs.length < maxLines) {
      logs.add(text);
    } else {
      logs.removeAt(0);
      logs.add(text);
    }
    if (autoScroll) {
      setState(() {});
      scrollToEnd();
    }
  }

  void scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
      WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
        if (controller.hasClients) {
          controller.animateTo(controller.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear);
        }
      });
    });
  }

  ScrollController controller = ScrollController();
  bool open = true;
  final List<String> tokens = [
    '[info]',
    '[INFO]',
    '[error]',
    '[ERROR]',
    'warning',
    'WARNING',
    'warn',
    '[WARN]',
    '[debug]',
    '[DEBUG]',
  ];

  Widget highlightText(String text) {
    if (text == "") {
      return const Text("");
    }
    List<InlineSpan>? children = [];
    String token = '';
    List<String> infos = [];
    for (var i = 0; i < tokens.length; i++) {
      if (text.contains(tokens[i])) {
        token = tokens[i];
        infos = text.split(token);
        break;
      }
    }
    if (infos.isEmpty) {
      infos = [text];
    }
    for (var i = 0; i < infos.length; i++) {
      final info = infos[i];
      children.add(TextSpan(
          text: info,
          style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.normal)));
      if (i != infos.length - 1) {
        Color color = Colors.green;
        if (token == "[info]" || token == '[INFO]') {
          color = Colors.green;
        } else if (token == '[error]' || token == '[ERROR]') {
          color = Colors.red;
        } else if (token == '[warn]' ||
            token == '[WARN]' ||
            token == '[warning]' ||
            token == '[WARNING]') {
          color = Colors.orange;
        }
        children.add(TextSpan(
            text: token,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            )));
      }
    }
    // children.add(const TextSpan(
    //     text: "\n", style: TextStyle(fontWeight: FontWeight.normal)));
    final TextSpan textSpan = TextSpan(children: children);
    return SelectableText.rich(textSpan);
  }

  String logUrl = "";
  String logNonce = '';

  Widget get autoScrollBtn => IconButton(
      onPressed: () {
        setState(() {
          autoScroll = !autoScroll;
          if (autoScroll) {
            scrollToEnd();
          }
        });
      },
      icon: autoScroll
          ? const Icon(
              Icons.download,
              color: Colors.blue,
            )
          : const Icon(Icons.download_outlined));

  Widget get clearBtn => IconButton(
      onPressed: () {
        logs = [];
        setState(() {});
      },
      icon: const Icon(
        Icons.cleaning_services_rounded,
        color: Colors.red,
      ));

  @override
  Widget build(BuildContext context) {
    final view = ListView.builder(
        controller: controller,
        itemBuilder: (BuildContext context, int index) {
          final text = logs[index];
          return highlightText(text);
        },
        itemCount: logs.length);

    final Widget swi = Switch(
        value: open,
        onChanged: (v) {
          setState(() {
            open = v;
            if (!v) {
              logs = [];
            }
          });
        });

    List<Widget> children = [
      const Row(
        children: [
          Flexible(child: Divider()),
          Padding(
            padding: EdgeInsets.only(left: 5, right: 5),
            child: Text("Log"),
          ),
          Flexible(child: Divider()),
        ],
      ),
      Row(
        children: [
          Expanded(child: clearBtn),
          Expanded(child: autoScrollBtn),
          Expanded(child: swi),
        ],
      ),
    ];
    if (open) {
      children.add(Flexible(child: view));
    }
    return Column(children: children);
  }
}
