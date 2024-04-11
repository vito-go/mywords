import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _globalPrefs;

Future<void> initGlobalPrefs() async {
  _globalPrefs = await SharedPreferences.getInstance();
}

final prefs = _Prefs();

class _Prefs {
  String get _defaultHomeIndex => "mywords:_defaultHomeIndex";

  String get _tipHideWithLevel =>
      "mywords:_tipHideWithLevel:"; //-1 累计，0 all, 1 ,2 ,3

  String get _syncToadyWordCount => "mywords:_syncToadyWordCount";

  String get _syncByRemoteArchived => "mywords:_syncByRemoteArchived";

  String get _syncKnownWords => "mywords:_syncKnownWords";

  String get _showWordLevel => "mywords:_showWordLevel";

  String get _syncIpPortCode => "mywords:_syncIpPortCode";

  String get _toastSlideToDelete => "mywords:_toastSlideToDelete";

  String get _keyThemeMode => "mywords:themeMode";

  bool get isDark => themeMode == ThemeMode.dark;

  ThemeMode get themeMode {
    final key = _keyThemeMode;
    final result = _globalPrefs.getInt(key);
    if (result == null) {
      _globalPrefs.setInt(key, 2);
      return ThemeMode.light;
    }
    if (result == 0) {
      return ThemeMode.system;
    }
    if (result == 1) {
      return ThemeMode.dark;
    }
    if (result == 2) {
      return ThemeMode.light;
    }
    return ThemeMode.system;
  }

  // 0 system 1 dark 2 light
  set themeMode(ThemeMode value) {
    final key = _keyThemeMode;
    if (value == ThemeMode.system) {
      _globalPrefs.setInt(key, 0);
    } else if (value == ThemeMode.dark) {
      _globalPrefs.setInt(key, 1);
    } else if (value == ThemeMode.light) {
      _globalPrefs.setInt(key, 2);
    }
  }

  // port_code
  List<String> get syncIpPortCode =>
      _globalPrefs.getStringList(_syncIpPortCode) ?? [];

  set syncIpPortCode(List<String> s) {
    _globalPrefs.setStringList(_syncIpPortCode, s);
  }

  bool get toastSlideToDelete =>
      _globalPrefs.getBool(_toastSlideToDelete) ?? false;

  set toastSlideToDelete(bool _) {
    _globalPrefs.setBool(_toastSlideToDelete, true);
  }

  bool get syncToadyWordCount =>
      _globalPrefs.getBool(_syncToadyWordCount) ?? false;

  set syncToadyWordCount(bool v) {
    _globalPrefs.setBool(_syncToadyWordCount, v);
  }

  bool get syncByRemoteArchived =>
      _globalPrefs.getBool(_syncByRemoteArchived) ?? false;

  set syncByRemoteArchived(bool v) {
    _globalPrefs.setBool(_syncByRemoteArchived, v);
  }

  bool get syncKnownWords => _globalPrefs.getBool(_syncKnownWords) ?? false;

  set syncKnownWords(bool v) {
    _globalPrefs.setBool(_syncKnownWords, v);
  }

  int get showWordLevel => _globalPrefs.getInt(_showWordLevel) ?? 0;

  set showWordLevel(int value) {
    _globalPrefs.setInt(_showWordLevel, value);
  }

  int get defaultHomeIndex => _globalPrefs.getInt(_defaultHomeIndex) ?? 0;

  set defaultHomeIndex(int value) {
    _globalPrefs.setInt(_defaultHomeIndex, value);
  }

  bool getTipHideWithLevel(String tip) {
    final key = "$_tipHideWithLevel$tip";
    return _globalPrefs.getBool(key) ?? false;
  }

  setTipHideWithLevel(String tip, bool hide) {
    final key = "$_tipHideWithLevel$tip";
    return _globalPrefs.setBool(key, hide);
  }
}
