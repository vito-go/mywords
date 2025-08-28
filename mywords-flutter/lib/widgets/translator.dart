import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/util/util_native.dart'
    if (dart.library.html) 'package:mywords/util/util_web.dart';
import 'package:url_launcher/url_launcher.dart';

import '../libso/handler.dart';
import '../libso/types.dart';

void showTranslation(BuildContext context, String text) async {
  final original = Row(
    children: [
      Flexible(child: SingleChildScrollView(child: SelectableText(text))),
      IconButton(
          onPressed: () {
            copyToClipBoard(context, text);
          },
          icon: Icon(Icons.copy)),
    ],
  );
  showDialog(
      context: context,
      builder: (BuildContext context) {
        final waiting = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: original),
            const Divider(),
            const Center(child: CircularProgressIndicator()),
            const Divider(),
          ],
        );
        final child = FutureBuilder(
            future: compute((message) => handler.translate(message), text),
            builder:
                (BuildContext context, AsyncSnapshot<Translation> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return waiting;
                case ConnectionState.waiting:
                  return waiting;
                case ConnectionState.active:
                  return waiting;
                case ConnectionState.done:
                  final translation = snapshot.data!;
                  if (translation.errCode != 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: original),
                        const Divider(),
                        Flexible(
                            child: Row(
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.red,
                            ),
                            Flexible(
                                child: SingleChildScrollView(
                                    child: SelectableText(translation.errMsg))),
                          ],
                        )),
                        Divider(),
                        Text(
                          "Powered by ${translation.poweredBy}",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        )
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      original,
                      const Divider(),
                      Flexible(
                          child: Row(
                        children: [
                          Flexible(
                              child: SingleChildScrollView(
                                  child: SelectableText(translation.result))),
                          IconButton(
                              onPressed: () {
                                copyToClipBoard(context, translation.result);
                              },
                              icon: Icon(Icons.copy)),
                        ],
                      )),
                      const Divider(),
                      Text(
                        "Powered by ${translation.poweredBy}",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    ],
                  );
              }
            });

        final width = getPlatformWebWidth(context);
        return Dialog(
            insetPadding: const EdgeInsets.only(
                top: 20.0, bottom: 100.0, left: 20, right: 20),
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(width: width, child: child)));
      });
}

WidgetSpan buildTranslateWidgetSpan(BuildContext context, String text) {
   final trans = WidgetSpan(
      child: InkWell(
    child: Icon(Icons.g_translate,
        color: prefs.isDark ? null : Theme.of(context).primaryColor),
    onTap: () {
      final url = Uri.encodeFull(
          'https://translate.google.com/?sl=auto&tl=zh-CN&text=$text');
      // launchUrlString(url);
      openInGoogleTranslate(text);
      // showTranslation(context, text);
    },
  ));
  return trans;
}


Future<void> openInGoogleTranslate(String text,
    {String from = 'auto', String to = 'zh-CN'}) async {
  final encoded = Uri.encodeComponent(text);

  // 1) ★ 最稳：用 Android 分享 Intent 直接把文本交给 Google 翻译 App
  if (Platform.isAndroid) {
    try {
      final shareIntent = AndroidIntent(
        action: 'android.intent.action.SEND',
        package: 'com.google.android.apps.translate',
        type: 'text/plain',
        arguments: {
          'android.intent.extra.TEXT': text,
        },
      );
      await shareIntent.launch();
      return;
    } catch (_) {}
  }

  // 2) 备用：尝试私有 scheme（并非所有机型都支持）
  try {
    final scheme1 = Uri.parse('googletranslate://?sl=$from&tl=$to&text=$encoded');
    if (await canLaunchUrl(scheme1)) {
      await launchUrl(scheme1, mode: LaunchMode.externalApplication);
      return;
    }
    final scheme2 = Uri.parse('googletranslate://translate?sl=$from&tl=$to&text=$encoded');
    if (await canLaunchUrl(scheme2)) {
      await launchUrl(scheme2, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}

  // 3) 网页版（正确带上 op=translate；注意必须 Uri.encodeComponent，不能有引号）
  final web = Uri.parse(
      'https://translate.google.com/?sl=$from&tl=$to&text=$encoded&op=translate');
  try {
    if (await canLaunchUrl(web)) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}

  // 4) 兜底：复制文本 → 打开（或引导安装）App
  await Clipboard.setData(ClipboardData(text: text));
  if (Platform.isAndroid) {
    try {
      final openApp = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.google.android.apps.translate',
      );
      await openApp.launch();
      return;
    } catch (_) {}

    final market = Uri.parse('market://details?id=com.google.android.apps.translate');
    if (await canLaunchUrl(market)) {
      await launchUrl(market, mode: LaunchMode.externalApplication);
      return;
    }
    final play = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.apps.translate');
    await launchUrl(play, mode: LaunchMode.externalApplication);
  }
}
