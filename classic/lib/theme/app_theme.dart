import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// `red` and `blue` share their ids with the other Tiyn style, so the choice
/// survives a backup moving between the two. Any other id, such as `clay`,
/// falls back to red.
enum AccentId {
  red('red', 'Красный', Color(0xFFD71921), Color(0xFFF2555B)),
  blue('blue', 'Синий', Color(0xFF2F5BD3), Color(0xFF7FA0F5)),
  orange('orange', 'Оранжевый', Color(0xFFD9480F), Color(0xFFFF8A4C));

  final String id;
  final String label;
  final Color light, dark;
  const AccentId(this.id, this.label, this.light, this.dark);

  static AccentId parse(Object? raw) {
    for (final a in values) {
      if (a.id == raw) return a;
    }
    return red;
  }

  Color forBrightness(Brightness b) => b == Brightness.dark ? dark : light;
}

class AppTheme extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;
  AccentId accent = AccentId.red;

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
    accent = AccentId.red;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    if (m == mode) return;
    mode = m;
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
