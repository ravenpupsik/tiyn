// Previews of Settings and the backup sheets into PREVIEW_DIR.
// Run: PREVIEW_DIR=/path flutter test test/backup_previews_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

import 'package:money_app/app.dart';
import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/plan.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/screens/settings/backup_snacks.dart';
import 'package:money_app/screens/settings/settings_page.dart';
import 'package:money_app/services/backup_io.dart';
import 'package:money_app/services/reminder.dart';

final _dir = Platform.environment['PREVIEW_DIR'];

Future<void> shot(WidgetTester tester, String name, Size size) async {
  await tester.runAsync(() async {
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final img = await layer.toImage(Offset.zero & (size * 3), pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Txn tx(
  String id,
  int amount,
  DateTime d,
  String cat,
  String note, {
  TxnKind kind = TxnKind.expense,
}) =>
    Txn(id: id, amount: amount, kind: kind, category: cat, note: note, date: d);

/// App data: the same as in the home preview.
Map<String, Object> appData() {
  final now = DateTime.now();
  DateTime at(int back, int h, int m) =>
      DateTime(now.year, now.month, now.day - back, h, m);
  final items = [
    tx(
      '1',
      36000,
      at(1, 12, 0),
      'Стипендия',
      'за ноябрь',
      kind: TxnKind.income,
    ),
    tx('3', 900, at(0, 14, 12), 'Кафе', 'кофе'),
    tx('4', 1200, at(0, 13, 5), 'Еда', 'столовая'),
    tx('5', 100, at(0, 8, 40), 'Транспорт', 'автобус'),
    tx('6', 850, at(1, 17, 40), 'Покупки', 'тетради'),
  ];
  return {
    'transactions': jsonEncode([for (final t in items) t.toJson()]),
    'plans': jsonEncode([
      const Plan(
        id: 'p1',
        title: 'Зубной',
        amount: 15000,
        category: 'Другое',
      ).toJson(),
    ]),
    'piggy_start': 19000,
    'last_cat_expense': 'Кафе',
    'last_cat_income': 'Стипендия',
    'remind_on': true,
    'remind_h': 21,
    'remind_m': 0,
  };
}

/// Backup file from the mockup: 128 entries, balance 45 000, piggy bank 19 000.
Uint8List mockFile() {
  final items = <Map<String, dynamic>>[
    tx(
      'inc',
      57700,
      DateTime(2026, 11, 1, 12),
      'Стипендия',
      '',
      kind: TxnKind.income,
    ).toJson(),
    for (var i = 0; i < 127; i++)
      tx('e$i', 100, DateTime(2026, 11, 2 + i % 12, 12), 'Еда', '').toJson(),
  ];
  return Uint8List.fromList(
    utf8.encode(
      Backup.encode({
        'app': 'tiyn',
        'version': 1,
        'createdAt': '2026-11-14T17:55:00+05:00',
        'data': {
          'transactions': items,
          'plans': [],
          'piggyStart': 19000,
          'remind': {'on': true, 'h': 21, 'm': 0},
        },
      }),
    ),
  );
}

void main() {
  const size = Size(360, 800);

  for (final dark in [false, true]) {
    final tag = dark ? 'dark' : 'light';

    Future<void> setup(WidgetTester tester, Map<String, Object> prefs) async {
      await loadGlinaFonts();
      debugDisableShadows = false;
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 28 * 3, bottom: 16 * 3);
      tester.view.viewPadding = tester.view.padding;
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
        debugDisableShadows = true;
      });
      SharedPreferences.setMockInitialValues(prefs);
      await Reminder.reloadSettings();
      introEnabled = false;
      await tester.pumpWidget(const TiynApp());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Настройки'));
      await tester.pumpAndSettle();
    }

    final withLast = {
      ...appData(),
      'last_backup_at': '2026-11-14T17:55:00+05:00',
    };

    testWidgets('settings $tag', (tester) async {
      await setup(tester, withLast);
      showBackupSnack(
        tester.element(find.byType(SettingsPage)),
        'Копия сохранена',
        bottom: 8,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await shot(tester, 'backup_settings_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('empty $tag', (tester) async {
      await setup(tester, appData());
      await shot(tester, 'backup_empty_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('confirm $tag', (tester) async {
      await setup(tester, withLast);
      BackupIO.pickFile = () async =>
          (name: 'tiyn_2026-11-14.json', bytes: mockFile());
      await tester.tap(find.text('Восстановить из копии'));
      await tester.pumpAndSettle();
      await shot(tester, 'backup_confirm_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('error $tag', (tester) async {
      await setup(tester, withLast);
      BackupIO.pickFile = () async => (
        name: 'photo.json',
        bytes: Uint8List.fromList(utf8.encode('привет')),
      );
      await tester.tap(find.text('Восстановить из копии'));
      await tester.pumpAndSettle();
      await shot(tester, 'backup_error_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('error newer $tag', (tester) async {
      await setup(tester, withLast);
      BackupIO.pickFile = () async => (
        name: 'tiyn_future.json',
        bytes: Uint8List.fromList(
          utf8.encode('{"app":"tiyn","version":99,"data":{}}'),
        ),
      );
      await tester.tap(find.text('Восстановить из копии'));
      await tester.pumpAndSettle();
      await shot(tester, 'backup_error_newer_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('restored $tag', (tester) async {
      await setup(tester, withLast);
      BackupIO.pickFile = () async => (
        name: 'tiyn_2026-11-14.json',
        bytes: Backup.encodeBytes({
          'app': 'tiyn',
          'version': 1,
          'createdAt': '2026-11-14T17:55:00+05:00',
          'data': {
            'transactions': [
              for (final t in jsonDecode(appData()['transactions']! as String))
                t,
            ],
            'plans': jsonDecode(appData()['plans']! as String),
            'piggyStart': 19000,
            'remind': {'on': true, 'h': 21, 'm': 0},
          },
        }),
      );
      await tester.tap(find.text('Восстановить из копии'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Заменить'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await shot(tester, 'backup_restored_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);
  }
}
