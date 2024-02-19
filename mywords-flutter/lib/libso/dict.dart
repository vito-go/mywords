import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mywords/libso/resp_data.dart';

import 'init.dart';

// func QueryWordLevel(wordC *C.char) *C.char
final _getUrlByWord = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('GetUrlByWord');

// getUrlByWord 返回防止携带word参数
String getUrlByWord(String word) {
  final wordC = word.toNativeUtf8();
  final resultC = _getUrlByWord(wordC);
  malloc.free(wordC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<String> respData =
      RespData.fromJson(jsonDecode(result), (json) => json as String);
  return respData.data??'';
}

// func   UpdateDictName(dataDirC, nameC *C.char) *C.char {
final _updateDictName = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>('UpdateDictName');

RespData<void> updateDictName(String dataDir, String name) {
  final dataDirC = dataDir.toNativeUtf8();
  final nameC = name.toNativeUtf8();
  final resultC = _updateDictName(dataDirC, nameC);
  malloc.free(dataDirC);
  malloc.free(nameC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<void> respData =
      RespData.fromJson(jsonDecode(result), (json) {});
  return respData;
}

// func SetDefaultDict(dataDirC *C.char) *C.char {
final _setDefaultDict = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('SetDefaultDict');

RespData<void> setDefaultDict(String basePath) {
  final basePathC = basePath.toNativeUtf8();
  final resultC = _setDefaultDict(basePathC);
  malloc.free(basePathC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<void> respData =
      RespData.fromJson(jsonDecode(result), (json) {});
  return respData;
}

// func DictList() *C.char {
final _dictList = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('DictList');

RespData<List<dynamic>> dictList() {
  final resultC = _dictList();
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<List<dynamic>> respData =
      RespData.fromJson(jsonDecode(result), (json) => json as List<dynamic>);
  return respData;
}

// func AddDict(dataDirC *C.char) *C.char {

final _addDict = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('AddDict');

RespData<void> addDict(String dataDir) {
  final dataDirC = dataDir.toNativeUtf8();
  final resultC = _addDict(dataDirC);
  malloc.free(dataDirC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<void> respData =
      RespData.fromJson(jsonDecode(result), (json) {});
  return respData;
}

// func DelDict(basePath *C.char) *C.char {
final _delDict = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('DelDict');

RespData<void> delDict(String basePath) {
  final basePathC = basePath.toNativeUtf8();
  final resultC = _delDict(basePathC);
  malloc.free(basePathC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<void> respData =
      RespData.fromJson(jsonDecode(result), (json) {});
  return respData;
}

// func SearchByKeyWord(keyWordC *C.char) *C.char {}
final _searchByKeyWord = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('SearchByKeyWord');

RespData<List<String>> searchByKeyWord(String word) {
  final wordC = word.toNativeUtf8();
  final resultC = _searchByKeyWord(wordC);
  malloc.free(wordC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<List<String>> respData =
      RespData.fromJson(jsonDecode(result), (json) => List<String>.from(json));
  return respData;
}

final _getBaseUrl = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('GetBaseUrl');

RespData<String> getBaseUrl() {
  final resultC = _getBaseUrl();
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<String> respData =
      RespData.fromJson(jsonDecode(result), (json) => json as String);
  return respData;
}

final _getDefaultDict = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('GetDefaultDict');

RespData<String> getDefaultDict() {
  final resultC = _getDefaultDict();
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<String> respData =
      RespData.fromJson(jsonDecode(result), (json) => json as String);
  return respData;
}


final _getHTMLRenderContentByWord = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('GetHTMLRenderContentByWord');

RespData<String> getHTMLRenderContentByWord(String word) {
  final wordC = word.toNativeUtf8();
  final resultC = _getHTMLRenderContentByWord(wordC);
  malloc.free(wordC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<String> respData =
      RespData.fromJson(jsonDecode(result), (json) => json as String);
  return respData;
}

final _fixMyKnownWords = nativeAddLib.lookupFunction<Pointer<Utf8> Function(),
    Pointer<Utf8> Function()>('FixMyKnownWords');

RespData<void> fixMyKnownWords() {
  final resultC = _fixMyKnownWords();
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<void> respData =
      RespData.fromJson(jsonDecode(result), (json) {});
  return respData;
}

final _finalHtmlBasePathWithOutHtml = nativeAddLib.lookupFunction<
    Pointer<Utf8> Function(Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<Utf8>)>('FinalHtmlBasePathWithOutHtml');

String finalHtmlBasePathWithOutHtml(String word) {
  final wordC = word.toNativeUtf8();
  final resultC = _finalHtmlBasePathWithOutHtml(wordC);
  malloc.free(wordC);
  final result = resultC.toDartString();
  malloc.free(resultC);
  final RespData<String> respData =
      RespData.fromJson(jsonDecode(result), (json) => json as String);
  return respData.data??"";
}
