import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_app/app.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/screens/stats/period_controls.dart';
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/day_bars.dart';

Txn tx(
  int amount,
  DateTime d,
  String cat, {
  TxnKind kind = TxnKind.expense,
  required String id,
}) => Txn(id: id, amount: amount, kind: kind, category: cat, note: '', date: d);

void main() {
  testWidgets('DayBars: тап по всей колонке, подсказка, точка у пустого дня', (
    tester,
  ) async {
    final today = DateTime(2026, 11, 11);
    final days = [
      for (var i = 6; i >= 0; i--)
        DayBarData(
          date: DateTime(2026, 11, 11 - i),
          // 5 Nov Thu ... 7 Nov Sat (4120), 8 Nov Sun = 0
          amount: const [1500, 1200, 4120, 0, 900, 300, 1400][6 - i],
          isToday: DateTime(2026, 11, 11 - i) == today,
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 336,
              child: DayBars(days: days, todayColor: kAccentLight),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Сб'), findsOneWidget);
    expect(find.text('Сб · −4 120 ₸'), findsNothing);

    // Tap next to the bar, not on it (15 dp left of the "Сб" label).
    final sat = tester.getCenter(find.text('Сб'));
    await tester.tapAt(sat + const Offset(-15, -20));
    await tester.pump();
    expect(find.text('Сб · −4 120 ₸'), findsOneWidget);

    // A second tap hides it.
    await tester.tapAt(sat + const Offset(-15, -20));
    await tester.pump();
    expect(find.text('Сб · −4 120 ₸'), findsNothing);

    // Empty day.
    await tester.tap(find.text('Вс'));
    await tester.pump();
    expect(find.text('Вс · 0 ₸'), findsOneWidget);

    // A tap outside the widget hides it.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text('Вс · 0 ₸'), findsNothing);
  });

  testWidgets('Главная: итог дня считает только расходы', (tester) async {
    final now = DateTime.now();
    final y = DateTime(now.year, now.month, now.day - 1, 12);
    SharedPreferences.setMockInitialValues({
      'transactions': jsonEncode([
        tx(678, y, 'Еда', id: 'a').toJson(),
        tx(100, y, 'Кафе', id: 'b').toJson(),
        tx(25000, y, 'Стипендия', kind: TxnKind.income, id: 'c').toJson(),
        tx(5000, y, '', kind: TxnKind.toPiggy, id: 'd').toJson(),
      ]),
    });
    await tester.pumpWidget(const TiynApp());
    await tester.pumpAndSettle();
    expect(find.text('Вчера'), findsOneWidget);
    expect(
      find.text('−778 ₸'),
      findsOneWidget,
    ); // 678 + 100, без дохода и перевода
  });

  testWidgets('Главная: день только с доходом без суммы', (tester) async {
    final now = DateTime.now();
    final y = DateTime(now.year, now.month, now.day - 1, 12);
    SharedPreferences.setMockInitialValues({
      'transactions': jsonEncode([
        tx(25000, y, 'Стипендия', kind: TxnKind.income, id: 'c').toJson(),
      ]),
    });
    await tester.pumpWidget(const TiynApp());
    await tester.pumpAndSettle();
    expect(find.text('Вчера'), findsOneWidget);
    expect(find.textContaining('−'), findsNothing);
  });

  testWidgets('Статистика: чипы, 7 дней, Период, сброс на Месяц', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10);
    SharedPreferences.setMockInitialValues({
      'transactions': jsonEncode([
        tx(1400, today, 'Еда', id: 'a').toJson(),
        tx(600, today, 'Кафе', id: 'b').toJson(),
        tx(9000, today, 'Стипендия', kind: TxnKind.income, id: 'c').toJson(),
      ]),
    });
    await tester.pumpWidget(const TiynApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Статистика'));
    await tester.pumpAndSettle();

    // Month by default: no bars and no pill.
    expect(find.text('7 дней'), findsOneWidget);
    expect(find.text('Месяц'), findsOneWidget);
    expect(find.text('Период'), findsOneWidget);
    expect(find.byType(DayBars), findsNothing);
    expect(find.byType(PeriodPill), findsNothing);
    expect(find.text('70%'), findsOneWidget); // 1400 из 2000
    expect(
      find.text('В среднем ${formatMoney(2000 ~/ now.day)} в день'),
      findsOneWidget,
    );

    // 7 days: bars, average over 7.
    await tester.tap(find.text('7 дней'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBars), findsOneWidget);
    expect(
      find.text('В среднем ${formatMoney(2000 ~/ 7)} в день'),
      findsOneWidget,
    );

    // Period: the date picker opens right away; closed without picking.
    await tester.tap(find.text('Период'));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(
      find.byType(PeriodPill),
      findsOneWidget,
    ); // осталось «последние 7 дней»
    expect(find.byType(DayBars), findsNothing);
    expect(
      find.text('В среднем ${formatMoney(2000 ~/ 7)} в день'),
      findsOneWidget,
    );

    // Back to home and return: Month again.
    await tester.tap(find.text('Главная'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Статистика'));
    await tester.pumpAndSettle();
    expect(find.byType(PeriodPill), findsNothing);
    expect(
      find.text('В среднем ${formatMoney(2000 ~/ now.day)} в день'),
      findsOneWidget,
    );
  });
}
