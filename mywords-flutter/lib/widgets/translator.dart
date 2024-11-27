import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/util/util.dart';
import 'package:mywords/util/util_native.dart'
    if (dart.library.html) 'package:mywords/util/util_web.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
      launchUrlString(url);
      // showTranslation(context, text);
    },
  ));
  return trans;
}
