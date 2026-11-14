import 'dart:convert';
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
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';

Future<SharedPreferences> prefsWith(Map<String, Object> v) async {
  SharedPreferences.setMockInitialValues(v);
  return SharedPreferences.getInstance();
}

String fileWith(Map<String, dynamic> data) => jsonEncode({
  'app': 'tiyn',
  'version': 1,
  'createdAt': '2026-11-14T17:55:00+05:00',
  'data': data,
});

void main() {
  tearDown(appTheme.reset);

  group('палитры', () {
    test('акценты точно по таблице ТЗ', () {
      const table = {
        AccentId.clay: (0xFFB84728, 0xFF9E3A1E, 0xFFE39270),
        AccentId.red: (0xFFD71921, 0xFFB3151C, 0xFFF28C85),
        AccentId.blue: (0xFF2F5DA8, 0xFF2A5396, 0xFF8FB0E6),
      };
      for (final e in table.entries) {
        final l = Glina.palette(Brightness.light, e.key);
        final d = Glina.palette(Brightness.dark, e.key);
        expect(l.accent.toARGB32(), e.value.$1, reason: '${e.key} light');
        expect(l.accentText.toARGB32(), e.value.$2, reason: '${e.key} text');
        expect(d.accent.toARGB32(), e.value.$3, reason: '${e.key} dark');
        expect(d.accentText.toARGB32(), e.value.$3);
      }
    });

    test('меняются только accent и accentText, остальное как у Глины', () {
      for (final b in Brightness.values) {
        final base = Glina.palette(b);
        for (final a in AccentId.values) {
          final p = Glina.palette(b, a);
          expect(p.bg, base.bg);
          expect(p.surf, base.surf);
          expect(p.surf2, base.surf2);
          expect(p.line, base.line);
          expect(p.ink, base.ink);
          expect(p.ink2, base.ink2);
          expect(p.ink3, base.ink3);
          expect(p.pos, base.pos);
          expect(p.onAccent, base.onAccent);
        }
      }
      expect(Glina.palette(Brightness.light).onAccent.toARGB32(), 0xFFFFF7F0);
      expect(Glina.palette(Brightness.dark).onAccent.toARGB32(), 0xFF1A1613);
    });

    test('контраст accentText и dark accent на поверхности не ниже 4.5', () {
      double lum(Color c) => c.computeLuminance();
      double ratio(Color a, Color b) {
        final x = lum(a), y = lum(b);
        return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
      }

      for (final b in Brightness.values) {
        for (final a in AccentId.values) {
          final p = Glina.palette(b, a);
          expect(ratio(p.accentText, p.surf), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('неизвестный акцент и режим превращаются в умолчание', () {
      expect(AccentId.parse('green'), AccentId.clay);
      expect(AccentId.parse(null), AccentId.clay);
      expect(AccentId.parse(7), AccentId.clay);
      expect(AccentId.parse('blue'), AccentId.blue);
      expect(parseThemeMode('sepia'), ThemeMode.system);
      expect(parseThemeMode(null), ThemeMode.system);
      expect(parseThemeMode('dark'), ThemeMode.dark);
    });

    test(
      'действие снекбара: accentText противоположной темы того же акцента',
      () {
        for (final a in AccentId.values) {
          expect(
            glinaTheme(Brightness.dark, a).snackBarTheme.actionTextColor,
            Glina.palette(Brightness.light, a).accentText,
          );
          expect(
            glinaTheme(Brightness.light, a).snackBarTheme.actionTextColor,
            Glina.palette(Brightness.dark, a).accentText,
          );
        }
        expect(
          glinaTheme(
            Brightness.dark,
            AccentId.clay,
          ).snackBarTheme.actionTextColor,
          const Color(0xFF9E3A1E),
        );
        expect(
          glinaTheme(
            Brightness.dark,
            AccentId.red,
          ).snackBarTheme.actionTextColor,
          const Color(0xFFB3151C),
        );
        expect(
          glinaTheme(
            Brightness.dark,
            AccentId.blue,
          ).snackBarTheme.actionTextColor,
          const Color(0xFF2A5396),
        );
      },
    );
  });

  group('хранение', () {
    test('по умолчанию «Как в системе» и «Глина»', () async {
      await prefsWith({});
      final t = AppTheme();
      await t.load();
      expect(t.mode, ThemeMode.system);
      expect(t.accent, AccentId.clay);
    });

    test('выбор пишется в prefs и читается после «перезапуска»', () async {
      final p = await prefsWith({});
      final t = AppTheme();
      var notified = 0;
      t.addListener(() => notified++);
      await t.setMode(ThemeMode.dark);
      await t.setAccent(AccentId.red);
      expect(notified, 2);
      expect(p.getString('theme_mode'), 'dark');
      expect(p.getString('accent'), 'red');

      final fresh = AppTheme();
      await fresh.load();
      expect(fresh.mode, ThemeMode.dark);
      expect(fresh.accent, AccentId.red);
    });

    test('мусор в prefs: system и clay', () async {
      await prefsWith({'theme_mode': 'sepia', 'accent': 'green'});
      final t = AppTheme();
      await t.load();
      expect(t.mode, ThemeMode.system);
      expect(t.accent, AccentId.clay);
    });
  });

  group('бэкап: тема и акцент', () {
    test('в файле есть themeMode и accent', () async {
      final p = await prefsWith({'theme_mode': 'light', 'accent': 'blue'});
      final d =
          Backup.snapshot(p, DateTime(2026, 11, 14))['data']
              as Map<String, dynamic>;
      expect(d['themeMode'], 'light');
      expect(d['accent'], 'blue');
      final e = await prefsWith({});
      final d2 =
          Backup.snapshot(e, DateTime(2026, 11, 14))['data']
              as Map<String, dynamic>;
      expect(d2['themeMode'], 'system');
      expect(d2['accent'], 'clay');
    });

    test('сохранить → восстановить на другом «телефоне»', () async {
      final a = await prefsWith({'theme_mode': 'dark', 'accent': 'red'});
      final text = Backup.encode(Backup.snapshot(a, DateTime(2026, 11, 14)));
      final b = await prefsWith({'theme_mode': 'light', 'accent': 'blue'});
      await Backup.restore(b, Backup.parse(text));
      expect(b.getString('theme_mode'), 'dark');
      expect(b.getString('accent'), 'red');
    });

    test('старая копия без полей оставляет текущие значения', () async {
      final b = await prefsWith({'theme_mode': 'light', 'accent': 'blue'});
      final f = Backup.parse(fileWith({'transactions': []}));
      expect(f.themeMode, isNull);
      expect(f.accent, isNull);
      await Backup.restore(b, f);
      expect(b.getString('theme_mode'), 'light');
      expect(b.getString('accent'), 'blue');
    });

    test(
      'неизвестный акцент и режим в копии: clay и system, не ошибка',
      () async {
        final b = await prefsWith({'theme_mode': 'light', 'accent': 'blue'});
        final f = Backup.parse(
          fileWith({'themeMode': 'sepia', 'accent': 'green'}),
        );
        expect(f.accent, 'clay');
        expect(f.themeMode, 'system');
        await Backup.restore(b, f);
        expect(b.getString('accent'), 'clay');
        expect(b.getString('theme_mode'), 'system');
      },
    );

    test('«Отменить» возвращает прежние тему и акцент', () async {
      final b = await prefsWith({'theme_mode': 'light', 'accent': 'blue'});
      await Backup.restore(
        b,
        Backup.parse(fileWith({'themeMode': 'dark', 'accent': 'red'})),
      );
      expect(b.getString('accent'), 'red');
      await Backup.undo(b);
      expect(b.getString('theme_mode'), 'light');
      expect(b.getString('accent'), 'blue');
    });

    test('версия копии остаётся 1', () async {
      final p = await prefsWith({});
      expect(Backup.snapshot(p, DateTime.now())['version'], 1);
    });
  });

  group('экран', () {
    Future<void> setup(WidgetTester tester, Map<String, Object> prefs) async {
      await loadGlinaFonts();
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
      await appTheme.load(); // как main(): до первого кадра
      await Reminder.reloadSettings();
      introEnabled = false;
      await tester.pumpWidget(const TiynApp());
      await tester.pumpAndSettle();
    }

    Glina gOf(WidgetTester t) =>
        Theme.of(t.element(find.byType(Scaffold).first)).extension<Glina>()!;

    Future<void> openSettings(WidgetTester t) async {
      await t.tap(find.bySemanticsLabel('Настройки'));
      await t.pumpAndSettle();
    }

    testWidgets('первый кадр сразу в выбранной теме и акценте', (t) async {
      await setup(t, {'theme_mode': 'dark', 'accent': 'blue'});
      // platform is light, but dark is chosen
      expect(
        Theme.of(t.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
      expect(
        gOf(t).accent,
        Glina.palette(Brightness.dark, AccentId.blue).accent,
      );
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
      expect(find.text('Как в системе'), findsNWidgets(2)); // строка и шторка
      expect(find.text('Светлая'), findsOneWidget);
      expect(find.text('Тёмная'), findsOneWidget);

      await t.tap(find.text('Тёмная'));
      await t.pumpAndSettle();
      expect(gOf(t).dark, isTrue);
      expect(find.text('Тёмная'), findsOneWidget); // значение в строке
      final p = await SharedPreferences.getInstance();
      expect(p.getString('theme_mode'), 'dark');

      await t.tap(find.text('Тема'));
      await t.pumpAndSettle();
      await t.tap(find.text('Светлая'));
      await t.pumpAndSettle();
      expect(gOf(t).dark, isFalse);
      expect(p.getString('theme_mode'), 'light');

      await t.tap(find.text('Тема'));
      await t.pumpAndSettle();
      await t.tap(find.text('Как в системе').last);
      await t.pumpAndSettle();
      expect(p.getString('theme_mode'), 'system');
      expect(gOf(t).dark, isFalse); // платформа светлая
    });

    testWidgets('акцент: шторка, смена сразу, галочка у выбранного', (t) async {
      await setup(t, {});
      await openSettings(t);
      expect(gOf(t).accent, const Color(0xFFB84728));
      await t.tap(find.text('Акцент'));
      await t.pumpAndSettle();
      for (final n in ['Глина', 'Красный', 'Синий']) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await t.tap(find.text('Красный'));
      await t.pumpAndSettle();
      expect(gOf(t).accent, const Color(0xFFD71921));
      expect(gOf(t).accentText, const Color(0xFFB3151C));
      final p = await SharedPreferences.getInstance();
      expect(p.getString('accent'), 'red');

      await t.tap(find.text('Синий'));
      await t.pumpAndSettle();
      expect(gOf(t).accent, const Color(0xFF2F5DA8));
      expect(p.getString('accent'), 'blue');
      // category colors and pos do not change
      expect(gOf(t).pos, Glina.light.pos);
    });

    testWidgets('восстановление применяет тему и акцент из копии сразу', (
      t,
    ) async {
      await setup(t, {'theme_mode': 'light', 'accent': 'blue'});
      await openSettings(t);
      BackupIO.pickFile = () async => (
        name: 'tiyn.json',
        bytes: utf8Bytes(fileWith({'themeMode': 'dark', 'accent': 'red'})),
      );
      await t.tap(find.text('Восстановить из копии'));
      await t.pumpAndSettle();
      await t.tap(find.text('Заменить'));
      await t.pumpAndSettle();
      expect(gOf(t).dark, isTrue);
      expect(
        gOf(t).accent,
        Glina.palette(Brightness.dark, AccentId.red).accent,
      );
      expect(appTheme.accent, AccentId.red);

      await t.tap(find.text('Отменить'));
      await t.pumpAndSettle();
      expect(gOf(t).dark, isFalse);
      expect(
        gOf(t).accent,
        Glina.palette(Brightness.light, AccentId.blue).accent,
      );
    });

    testWidgets('старая копия без тема/акцент не трогает оформление', (
      t,
    ) async {
      await setup(t, {'theme_mode': 'dark', 'accent': 'red'});
      await openSettings(t);
      BackupIO.pickFile = () async =>
          (name: 'old.json', bytes: utf8Bytes(fileWith({'transactions': []})));
      await t.tap(find.text('Восстановить из копии'));
      await t.pumpAndSettle();
      await t.tap(find.text('Заменить'));
      await t.pumpAndSettle();
      expect(appTheme.mode, ThemeMode.dark);
      expect(appTheme.accent, AccentId.red);
    });

    testWidgets('виджет рисуется в выбранном акценте', (t) async {
      await loadGlinaFonts();
      for (final dark in [false, true]) {
        await t.pumpWidget(
          BalanceWidgetCard(
            onHand: 827,
            free: 100,
            hasPlans: true,
            dark: dark,
            accent: AccentId.blue,
          ),
        );
        final want = Glina.palette(
          dark ? Brightness.dark : Brightness.light,
          AccentId.blue,
        ).accent;
        final plus = t.widgetList<Container>(find.byType(Container)).where((c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.shape == BoxShape.circle &&
              d.color == want;
        });
        expect(plus, isNotEmpty);
      }
    });
  });
}

Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

final _origPick = BackupIO.pickFile;
