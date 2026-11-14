import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/theme/tokens.dart';

class ThemeKeys {
  static const themeMode = 'theme_mode';
  static const accent = 'accent';
}

ThemeMode parseThemeMode(Object? raw) {
  for (final m in ThemeMode.values) {
    if (m.name == raw) return m;
  }
  return ThemeMode.system;
}

String themeModeLabel(ThemeMode m) => switch (m) {
  ThemeMode.system => 'Как в системе',
  ThemeMode.light => 'Светлая',
  ThemeMode.dark => 'Тёмная',
};

class AppTheme extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;
  AccentId accent = AccentId.clay;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final m = parseThemeMode(p.getString(ThemeKeys.themeMode));
    final a = AccentId.parse(p.getString(ThemeKeys.accent));
    if (m == mode && a == accent) return;
    mode = m;
    accent = a;
    notifyListeners();
  }

  void reset() {
    mode = ThemeMode.system;
    accent = AccentId.clay;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    if (m == mode) return;
    mode = m; // apply to the screen first, then persist
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(ThemeKeys.themeMode, m.name);
  }

  Future<void> setAccent(AccentId a) async {
    if (a == accent) return;
    accent = a;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(ThemeKeys.accent, a.id);
  }
}

final appTheme = AppTheme();
