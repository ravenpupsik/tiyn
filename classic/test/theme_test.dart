import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

import 'package:money_app/app.dart';
import 'package:money_app/data/backup_data.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/services/backup_io.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/services/tiyn_home_widget.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/widgets/backdrop.dart';

double _lum(Color c) {
  double f(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double contrast(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  final hi = x > y ? x : y, lo = x > y ? y : x;
  return (hi + 0.05) / (lo + 0.05);
}

String fileWith(Map<String, dynamic> data) => jsonEncode({
  'app': 'tiyn',
  'version': 1,
  'createdAt': '2026-11-14T17:55:00+05:00',
  'data': data,
});

Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

final _origPick = BackupIO.pickFile;

void main() {
  breathingEnabled = false;

  group('палитра', () {
    test('идентификаторы и умолчание', () {
      expect(
        [for (final a in AccentId.values) a.id],
        ['red', 'blue', 'orange'],
      );
      expect(AccentId.values.first, AccentId.red);
      expect(AccentId.red.light, const Color(0xFFD71921));
    });

    test('неизвестные id (clay, мусор, null) превращаются в red', () {
      for (final raw in ['clay', 'green', '', 'RED', 5, null]) {
        expect(AccentId.parse(raw), AccentId.red, reason: '$raw');
      }
      expect(AccentId.parse('blue'), AccentId.blue);
      expect(AccentId.parse('orange'), AccentId.orange);
    });

    test('режим темы: мусор превращается в system', () {
      expect(parseThemeMode('dark'), ThemeMode.dark);
      expect(parseThemeMode('light'), ThemeMode.light);
      expect(parseThemeMode('sepia'), ThemeMode.system);
      expect(parseThemeMode(null), ThemeMode.system);
    });

    test(
      'акценты читаются на поверхностях: не ниже 3:1, тёмные не ниже 4.5',
      () {
        const lightBg = Color(0xFFE9E9EC), darkBg = Color(0xFF050506);
        const darkCard = Color(0xFF1C1C1F);
        for (final a in AccentId.values) {
          expect(
            contrast(a.light, Colors.white),
            greaterThanOrEqualTo(4.2),
            reason: '${a.id} под белой галочкой',
          );
          expect(
            contrast(a.light, lightBg),
            greaterThanOrEqualTo(3.0),
            reason: '${a.id} светлая',
          );
          expect(
            contrast(a.dark, darkBg),
            greaterThanOrEqualTo(4.5),
            reason: '${a.id} тёмная',
          );
          expect(
            contrast(a.dark, darkCard),
            greaterThanOrEqualTo(4.5),
            reason: '${a.id} тёмная на карточке',
          );
        }
      },
    );

    testWidgets('основной и приглушённый текст на тёмной палитре не ниже 4.5', (
      t,
    ) async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      appTheme.reset();
      await appTheme.load();
      await t.pumpWidget(const TiynApp());
      await t.pumpAndSettle();
      final ctx = t.element(find.byType(Scaffold).first);
      final cs = Theme.of(ctx).colorScheme;
      final bg = const Color(0xFF050506);
      final card = Color.alphaBlend(
        const Color(0xFF1C1C1F).withValues(alpha: 0.62),
        bg,
      );
      final muted = cs.onSurface.withValues(alpha: 0.62);
      for (final surface in [bg, card]) {
        expect(
          contrast(Color.alphaBlend(cs.onSurface, surface), surface),
          greaterThanOrEqualTo(7),
        );
        expect(
          contrast(Color.alphaBlend(muted, surface), surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });

  group('хранение', () {
    test('по умолчанию «Как в системе» и красный', () async {
      SharedPreferences.setMockInitialValues({});
      final t = AppTheme();
      await t.load();
      expect(t.mode, ThemeMode.system);
      expect(t.accent, AccentId.red);
    });

    test('выбор пишется в prefs и читается заново', () async {
      SharedPreferences.setMockInitialValues({});
      final t = AppTheme();
      await t.setMode(ThemeMode.dark);
      await t.setAccent(AccentId.orange);
      final p = await SharedPreferences.getInstance();
      expect(p.getString('theme_mode'), 'dark');
      expect(p.getString('accent'), 'orange');
      final again = AppTheme();
      await again.load();
      expect(again.mode, ThemeMode.dark);
      expect(again.accent, AccentId.orange);
    });

    test('акцент Глины (clay) и мусор: system и red, без падения', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'weird',
        'accent': 'clay',
      });
      final t = AppTheme();
      await t.load();
      expect(t.mode, ThemeMode.system);
      expect(t.accent, AccentId.red);
    });
  });

  group('бэкап: тема и акцент', () {
    test('в файле есть themeMode и accent', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'accent': 'blue',
      });
      final p = await SharedPreferences.getInstance();
      final d = Backup.snapshot(p, DateTime(2026, 11, 14))['data'] as Map;
      expect(d['themeMode'], 'dark');
      expect(d['accent'], 'blue');
    });

    test('чужой акцент в копии сводится к red, версия остаётся 1', () async {
      final f = Backup.parse(
        fileWith({'themeMode': 'light', 'accent': 'clay'}),
      );
      expect(f.accent, 'red');
      expect(f.themeMode, 'light');
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      expect(Backup.snapshot(p, DateTime.now())['version'], 1);
    });

    test('копия без полей оформления оставляет текущие значения', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'accent': 'blue',
      });
      final p = await SharedPreferences.getInstance();
      await Backup.restore(p, Backup.parse(fileWith({'transactions': []})));
      expect(p.getString('theme_mode'), 'dark');
      expect(p.getString('accent'), 'blue');
    });

    test('«Отменить» возвращает прежние тему и акцент', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'accent': 'blue',
      });
      final p = await SharedPreferences.getInstance();
      await Backup.restore(
        p,
        Backup.parse(fileWith({'themeMode': 'light', 'accent': 'orange'})),
      );
      expect(p.getString('accent'), 'orange');
      await Backup.undo(p);
      expect(p.getString('theme_mode'), 'dark');
      expect(p.getString('accent'), 'blue');
    });
  });

  group('экран', () {
    Future<void> setup(WidgetTester tester, Map<String, Object> prefs) async {
      await loadTestFonts();
      tester.view.physicalSize = const Size(360, 800) * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 28 * 3, bottom: 16 * 3);
      tester.view.viewPadding = tester.view.padding;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
        BackupIO.pickFile = _origPick;
      });
      SharedPreferences.setMockInitialValues(prefs);
      appTheme.reset();
      await appTheme.load();
      await Reminder.reloadSettings();
      introEnabled = false;
      await tester.pumpWidget(const TiynApp());
      await tester.pumpAndSettle();
    }

    ThemeData themeOf(WidgetTester t) =>
        Theme.of(t.element(find.byType(Scaffold).first));

    Future<void> openSettings(WidgetTester t) async {
      await t.tap(find.bySemanticsLabel('Настройки'));
      await t.pumpAndSettle();
    }

    testWidgets('первый кадр сразу в выбранной теме и акценте', (t) async {
      await setup(t, {'theme_mode': 'dark', 'accent': 'blue'});
      expect(themeOf(t).brightness, Brightness.dark);
      expect(themeOf(t).colorScheme.secondary, AccentId.blue.dark);
    });

    testWidgets('Глина в prefs: clay и чужие ключи не ломают запуск', (
      t,
    ) async {
      await setup(t, {
        'accent': 'clay',
        'theme_mode': 'dark',
        'last_cat_expense': 'Кафе',
        'last_cat_income': 'Стипендия',
        'restore_undo': '{"app":"tiyn"}',
        'last_backup_at': '2026-11-14T17:55:00.000',
      });
      expect(themeOf(t).brightness, Brightness.dark);
      expect(themeOf(t).colorScheme.secondary, AccentId.red.dark);
      await openSettings(t);
      expect(find.textContaining('Последняя копия: '), findsOneWidget);
    });

    testWidgets('порядок секций и значения строк', (t) async {
      await setup(t, {});
      await openSettings(t);
      double y(String s) => t.getTopLeft(find.text(s)).dy;
      expect(y('Оформление'), lessThan(y('Напоминание')));
      expect(y('Напоминание'), lessThan(y('Данные')));
      expect(find.text('Тема'), findsOneWidget);
      expect(find.text('Как в системе'), findsOneWidget);
      expect(find.text('Акцент'), findsOneWidget);
    });

    testWidgets('тема: три варианта, применяется сразу и сохраняется', (
      t,
    ) async {
      await setup(t, {});
      await openSettings(t);
      await t.tap(find.text('Тема'));
      await t.pumpAndSettle();
      expect(find.text('Как в системе'), findsNWidgets(2));
      expect(find.text('Светлая'), findsOneWidget);
      expect(find.text('Тёмная'), findsOneWidget);

      await t.tap(find.text('Тёмная'));
      await t.pumpAndSettle();
      expect(themeOf(t).brightness, Brightness.dark);
      final p = await SharedPreferences.getInstance();
      expect(p.getString('theme_mode'), 'dark');

      await t.tap(find.text('Тема'));
      await t.pumpAndSettle();
      await t.tap(find.text('Светлая'));
      await t.pumpAndSettle();
      expect(themeOf(t).brightness, Brightness.light);
      expect(p.getString('theme_mode'), 'light');

      await t.tap(find.text('Тема'));
      await t.pumpAndSettle();
      await t.tap(find.text('Как в системе').last);
      await t.pump(const Duration(milliseconds: 300));
      await t.pumpAndSettle();
      expect(p.getString('theme_mode'), 'system');
    });

    testWidgets('акцент: шторка, смена сразу, галочка у выбранного', (t) async {
      await setup(t, {});
      await openSettings(t);
      expect(themeOf(t).colorScheme.secondary, AccentId.red.light);
      await t.tap(find.text('Акцент'));
      await t.pumpAndSettle();
      for (final n in ['Красный', 'Синий', 'Оранжевый']) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await t.tap(find.text('Синий'));
      await t.pumpAndSettle();
      expect(themeOf(t).colorScheme.secondary, AccentId.blue.light);
      final p = await SharedPreferences.getInstance();
      expect(p.getString('accent'), 'blue');

      await t.tap(find.text('Оранжевый'));
      await t.pumpAndSettle();
      expect(themeOf(t).colorScheme.secondary, AccentId.orange.light);
      expect(p.getString('accent'), 'orange');
    });

    testWidgets('восстановление применяет тему и акцент из копии сразу', (
      t,
    ) async {
      await setup(t, {'theme_mode': 'light', 'accent': 'blue'});
      await openSettings(t);
      BackupIO.pickFile = () async => (
        name: 'tiyn.json',
        bytes: utf8Bytes(fileWith({'themeMode': 'dark', 'accent': 'orange'})),
      );
      await t.tap(find.text('Восстановить из копии'));
      await t.pumpAndSettle();
      await t.tap(find.text('Заменить'));
      await t.pumpAndSettle();
      expect(themeOf(t).brightness, Brightness.dark);
      expect(themeOf(t).colorScheme.secondary, AccentId.orange.dark);

      await t.tap(find.text('Отменить'));
      await t.pumpAndSettle();
      expect(themeOf(t).brightness, Brightness.light);
      expect(themeOf(t).colorScheme.secondary, AccentId.blue.light);
    });

    testWidgets('напоминание: переключатель и время в настройках', (t) async {
      await setup(t, {'remind_on': false});
      await openSettings(t);
      expect(find.text('Напоминать в 21:00'), findsOneWidget);
      await t.tap(find.byType(Switch));
      await t.pumpAndSettle();
      expect(Reminder.on, isTrue);
      final p = await SharedPreferences.getInstance();
      expect(p.getBool('remind_on'), isTrue);
      await t.tap(find.text('Напоминать в 21:00'));
      await t.pumpAndSettle();
      expect(find.text('Время напоминания'), findsOneWidget);
    });

    testWidgets('виджет рисуется в выбранном акценте', (t) async {
      await loadTestFonts();
      for (final dark in [false, true]) {
        await t.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BalanceWidgetCard(
              onHand: 827,
              free: 100,
              hasPlans: true,
              dark: dark,
              accent: AccentId.blue,
            ),
          ),
        );
        final plus = t.widgetList<Container>(find.byType(Container)).where((c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.shape == BoxShape.circle &&
              d.color == AccentId.blue.light;
        });
        expect(plus, isNotEmpty);
        final dot = t.widgetList<Container>(find.byType(Container)).where((c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.shape == BoxShape.circle &&
              d.color == (dark ? AccentId.blue.dark : AccentId.blue.light) &&
              c.constraints?.maxWidth == 5;
        });
        expect(dot, isNotEmpty);
      }
    });
  });
}
