// Theme and accent previews into PREVIEW_DIR: home and the "+" sheet in all six
// combinations, Settings with appearance, the Theme and Accent sheets.
// Run: PREVIEW_DIR=/path flutter test test/theme_previews_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'previews_test.dart' show sample, shot;
import 'support/fonts.dart';

import 'package:money_app/app.dart';
import 'package:money_app/screens/editor/txn_editor.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/screens/settings/backup_snacks.dart';
import 'package:money_app/screens/settings/settings_page.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/tokens.dart';

final _dir = Platform.environment['PREVIEW_DIR'];

void main() {
  const size = Size(360, 800);

  Future<void> setup(
    WidgetTester tester, {
    required bool dark,
    required AccentId accent,
    Map<String, Object>? extra,
    bool settings = false,
  }) async {
    await loadGlinaFonts();
    debugDisableShadows = false;
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 28 * 3, bottom: 16 * 3);
    tester.view.viewPadding = tester.view.padding;
    // The platform is always light: the theme comes from the settings choice.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
      debugDisableShadows = true;
      appTheme.reset();
    });
    SharedPreferences.setMockInitialValues({
      ...sample(),
      'remind_on': true,
      'last_backup_at': '2026-11-14T17:55:00+05:00',
      'theme_mode': dark ? 'dark' : 'light',
      'accent': accent.id,
      ...?extra,
    });
    await appTheme.load();
    await Reminder.reloadSettings();
    introEnabled = false;
    await tester.pumpWidget(const TiynApp());
    await tester.pumpAndSettle();
    if (settings) {
      await tester.tap(find.bySemanticsLabel('Настройки'));
      await tester.pumpAndSettle();
    }
  }

  for (final dark in [false, true]) {
    final tag = dark ? 'dark' : 'light';
    for (final accent in AccentId.values) {
      final name = '${tag}_${accent.id}';

      testWidgets('home $name', (tester) async {
        await setup(tester, dark: dark, accent: accent);
        await shot(tester, 'home_$name', size);
        debugDisableShadows = true;
      }, skip: _dir == null);

      testWidgets('plus $name', (tester) async {
        await setup(tester, dark: dark, accent: accent);
        await tester.tap(find.bySemanticsLabel('Добавить'));
        await tester.pumpAndSettle();
        final fields = find.descendant(
          of: find.byType(TxnEditor),
          matching: find.byType(TextField),
        );
        await tester.enterText(fields.first, '900');
        await tester.enterText(fields.at(1), 'кофе');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await shot(tester, 'plus_$name', size);
        debugDisableShadows = true;
      }, skip: _dir == null);
    }

    testWidgets('settings $tag', (tester) async {
      await setup(tester, dark: dark, accent: AccentId.clay, settings: true);
      await shot(tester, 'settings_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('settings red $tag', (tester) async {
      await setup(tester, dark: dark, accent: AccentId.red, settings: true);
      await shot(tester, 'settings_red_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('theme sheet $tag', (tester) async {
      await setup(tester, dark: dark, accent: AccentId.clay, settings: true);
      await tester.tap(find.text('Тема'));
      await tester.pumpAndSettle();
      await shot(tester, 'theme_sheet_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('accent sheet $tag', (tester) async {
      await setup(tester, dark: dark, accent: AccentId.clay, settings: true);
      await tester.tap(find.text('Акцент'));
      await tester.pumpAndSettle();
      await shot(tester, 'accent_sheet_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('snack $tag', (tester) async {
      await setup(tester, dark: dark, accent: AccentId.red, settings: true);
      showBackupSnack(
        tester.element(find.byType(SettingsPage)),
        'Данные восстановлены',
        bottom: 8,
        actionLabel: 'Отменить',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await shot(tester, 'snack_red_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);
  }
}
