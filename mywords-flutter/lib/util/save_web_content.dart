import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

void localDownloadText(Uint8List content, String fileNamePrefix) {
  final href = "data:text/plain;charset=utf-8;base64,${base64.encode(content)}";
  AnchorElement(href: href)
    ..setAttribute("download", "$fileNamePrefix.txt")
    ..click()
    ..remove();
  return;
}

void localDownloadPdf(Uint8List content, String fileNamePrefix) {
  final href =
      "data:application/octet-stream;charset=utf-16le;base64,${base64.encode(content)}";
  AnchorElement(href: href)
    ..setAttribute("download", "$fileNamePrefix.pdf")
    ..click()
    ..remove();
}
