import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:mywords/common/global.dart';
import 'package:mywords/common/queue.dart';

import '../libso/handler.dart';
import '../util/util.dart';

void isolateEntry(SendPort sendPort) async {
  final port = ReceivePort();
  sendPort.send(port.sendPort);
  await for (final msg in port) {
    final responsePort = msg[0] as SendPort;
    final String response = handler.readMessage();
    responsePort.send(response);
    continue;
  }
}

void isolateLoopReadMessage() async {
  // If we're running in debug mode, don't start the isolate, as it will prevent hot reload from working.
  // if You want to debug this function, please comment out the following line.
  if (kDebugMode) return;
  // Clean up
  final receivePort = ReceivePort();
  final isolate = await Isolate.spawn(isolateEntry, receivePort.sendPort);
  final sendPort = await receivePort.first as SendPort;
  myPrint("isolateLoopReadMessage");
  for (int i = 0; true; i++) {
    final responsePort = ReceivePort();
    sendPort.send([responsePort.sendPort]);
    final String response = await responsePort.first as String;
    try {
      final separatorIdx = response.indexOf(":");
      final code = int.parse(response.substring(0, separatorIdx));
      final content = response.substring(separatorIdx + 1);
      myPrint("code: $code, content: $content");
      switch (code) {
        case 0:
          myPrint("receive error message: $content");
          continue;
        case 1:
          //更新单词列表
          myPrint("更新单词列表");
          // ["result",1]
          List<dynamic> param = jsonDecode(content);
          if (param.length >= 2) {
            if (param[0] is String && param[1] is int) {
              final word = param[0];
              final level = param[1];
              if (level == 0) {
                Global.allKnownWordsMap.remove(word);
                produceEvent(EventType.updateKnownWord);
              } else {
                Global.allKnownWordsMap[word] = level;
                produceEvent(EventType.updateKnownWord);
              }
            }
          }
          break;
        case 2:
          break;
        case 3:
          break;
        case 20:
          break;
        case 30:
          // readFromDB
          break;
        case 100:
          break;
        case 101:
          break;
        case 1000:
          myPrint(content);
          break;
      }
    } catch (e) {
      myPrint("isolateLoopReadMessage error: $e");
    } finally {
      responsePort.close();
    }
  }
  isolate.kill(priority: Isolate.immediate);
  receivePort.close();
}
