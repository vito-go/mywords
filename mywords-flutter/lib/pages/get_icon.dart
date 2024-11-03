import 'package:flutter/material.dart';
import '../config/config.dart';

Widget getIconBySourceURL(String rootURL,
    {double width = 28, double height = 28}) {
  final uri = Uri.tryParse(rootURL);
  if (uri == null) return const Icon(Icons.link);
  final String faviconURL = "${uri.scheme}://${uri.host}/favicon.ico";
  // final String iconFromGoogle =
  //     "https://www.google.com/s2/favicons?size=64&domain=${uri.host}";
  final String iconFromGStatic =
      "https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=${uri.scheme}://${uri.host}&size=64";
  final assetPath = assetPathByHost(uri.host);
  if (assetPath != "") {
    return ClipOval(
        child: Image.asset(assetPath, width: width, height: height));
  }
  // favicon
  return ClipOval(
    child: Image.network(
      faviconURL,
      width: width,
      height: height,
      cacheWidth: width.toInt(),
      cacheHeight: height.toInt(),
      errorBuilder: (context, _, __) {
        return ClipOval(
          child: Image.network(
            iconFromGStatic,
            width: width,
            height: height,
            cacheWidth: width.toInt(),
            cacheHeight: height.toInt(),
            errorBuilder: (context, _, __) {
              return const Icon(Icons.link);
            },
          ),
        );
      },
    ),
  );
}
