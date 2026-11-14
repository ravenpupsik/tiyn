// Draws screen previews into PREVIEW_DIR (without it the test writes nothing).
// Run: PREVIEW_DIR=/path flutter test test/previews_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

import 'package:money_app/app.dart';
import 'package:money_app/data/plan.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/services/tiyn_home_widget.dart';

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

Map<String, Object> sample() {
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
    tx('2', 290, at(12, 12, 0), 'Другое', ''),
    tx('3', 900, at(0, 14, 12), 'Кафе', 'кофе'),
    tx('4', 1200, at(0, 13, 5), 'Еда', 'столовая'),
    tx('5', 100, at(0, 8, 40), 'Транспорт', 'автобус'),
    tx('6', 850, at(1, 17, 40), 'Покупки', 'тетради'),
    tx('7', 2100, at(3, 12, 0), 'Еда', ''),
    tx('8', 1010, at(2, 12, 0), 'Транспорт', ''),
    tx('9', 1500, at(6, 12, 0), 'Кафе', ''),
    tx('10', 3200, at(5, 12, 0), 'Подписки', ''),
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
  };
}

void main() {
  const size = Size(360, 800);

  for (final dark in [false, true]) {
    final tag = dark ? 'dark' : 'light';

    Future<void> setup(
      WidgetTester tester, {
      bool intro = false,
      bool empty = false,
    }) async {
      await loadGlinaFonts();
      debugDisableShadows = false; // в тестах тени по умолчанию жёсткие
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
      });
      SharedPreferences.setMockInitialValues(empty ? {} : sample());
      introEnabled = intro;
      await tester.pumpWidget(const TiynApp());
      if (intro) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
      } else {
        await tester.pumpAndSettle();
      }
    }

    testWidgets('splash $tag', (tester) async {
      await setup(tester, intro: true);
      Future<void> frames(int n) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      // Progress ≈ (frames - 1) * 16 / 1000 after the ticker starts.
      await frames(14);
      await shot(tester, 'splash_1_start_$tag', size);
      await frames(14);
      await shot(tester, 'splash_2_dot_$tag', size);
      await frames(18);
      await shot(tester, 'splash_3_flight_$tag', size);
      await frames(40);
      await tester.pumpAndSettle();
      await shot(tester, 'splash_4_end_$tag', size);
      debugDisableShadows = true;
      introEnabled = false;
    }, skip: _dir == null);

    testWidgets('empty $tag', (tester) async {
      await setup(tester, empty: true);
      await shot(tester, 'home_empty_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('home $tag', (tester) async {
      await setup(tester);
      await shot(tester, 'home_$tag', size);
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      await shot(tester, 'stats_$tag', size);
      await tester.tap(find.text('Планы'));
      await tester.pumpAndSettle();
      await shot(tester, 'plans_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('quick $tag', (tester) async {
      await setup(tester);
      await shot(tester, 'home_quick_$tag', size);
      await tester.enterText(find.byType(TextField).first, '1500');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await shot(tester, 'home_quick_typed_$tag', size);
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      await shot(tester, 'home_scrolled_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('sheet $tag', (tester) async {
      await setup(tester);
      Future<void> open() async {
        await tester.tap(find.bySemanticsLabel('Добавить'));
        await tester.pumpAndSettle();
        // Amount autofocus: reset so frames a-c have no keyboard.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      await open();
      await shot(tester, 'sheet_a_$tag', size);
      await tester.enterText(find.byType(TextField).first, '900');
      await tester.enterText(find.byType(TextField).at(1), 'кофе');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await shot(tester, 'sheet_b_$tag', size);
      await tester.tap(find.text('Доход'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '36000');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await shot(tester, 'sheet_c_$tag', size);
      // d: keyboard (on Android the bottom system inset is 0 with it)
      await tester.tap(find.text('Трата'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '900');
      tester.view.padding = const FakeViewPadding(top: 28 * 3);
      tester.view.viewPadding = tester.view.padding;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280 * 3);
      await tester.pumpAndSettle();
      await shot(tester, 'sheet_d_$tag', size);
      debugDisableShadows = true;
    }, skip: _dir == null);

    testWidgets('widget $tag', (tester) async {
      await loadGlinaFonts();
      tester.view.physicalSize = const Size(400, 210) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: dark ? const Color(0xFF0E0C0B) : const Color(0xFFCFC6BE),
            child: Center(
              child: BalanceWidgetCard(
                onHand: 24850,
                free: 9850,
                hasPlans: true,
                dark: dark,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await shot(tester, 'widget_$tag', const Size(400, 210));
    }, skip: _dir == null);
  }
}
