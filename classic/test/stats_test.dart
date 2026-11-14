import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

import 'package:money_app/app.dart';
import 'package:money_app/data/period.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/screens/stats/category_stats.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

Txn e(int amount, String cat, DateTime d) => Txn(
  id: '$amount$cat${d.month}',
  amount: amount,
  kind: TxnKind.expense,
  category: cat,
  note: '',
  date: d,
);

void main() {
  breathingEnabled = false; // бесконечная анимация фона мешает pumpAndSettle
  test('Расходы по категориям: сортировка, «Другое», только этот месяц', () {
    final oct = DateTime(2026, 10, 5);
    final items = [
      e(7745, 'Подписки', oct),
      e(560, 'Транспорт', oct),
      e(300, 'Еда', oct),
      e(175, 'Еда', oct),
      e(100, '', oct),
      e(9999, 'Еда', DateTime(2026, 9, 5)),
      Txn(
        id: 'inc',
        amount: 50000,
        kind: TxnKind.income,
        category: 'Стипендия',
        note: '',
        date: oct,
      ),
      Txn(
        id: 'p',
        amount: 1000,
        kind: TxnKind.toPiggy,
        category: '',
        note: '',
        date: oct,
      ),
    ];
    final now = DateTime(2026, 10, 31);
    final r = expensesByCategory(
      items,
      StatPeriod.month(DateTime(2026, 10), now),
    );
    expect(r.map((x) => x.key.name).toList(), [
      'Подписки',
      'Транспорт',
      'Еда',
      'Другое',
    ]);
    expect(r[2].value, 475);
    expect(StatPeriod.month(DateTime(2026, 9), now).days, 30);
    expect(StatPeriod.month(DateTime(2026, 10), now).days, 31);
  });

  testWidgets('Экран статистики открывается и показывает категории', (
    tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'transactions': jsonEncode([
        e(7745, 'Подписки', now).toJson(),
        e(560, 'Транспорт', now).toJson(),
        e(475, 'Еда', now).toJson(),
      ]),
    });
    await tester.pumpWidget(const TiynApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расходы'));
    await tester.pumpAndSettle();
    expect(find.text('Статистика'), findsWidgets);
    expect(find.text('Подписки'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    await tester.tap(find.text('Подписки'));
    await tester.pumpAndSettle();
    expect(find.textContaining('7 745 ₸'), findsWidgets);
  });

  test('Проценты в сумме дают 100', () {
    final r = roundPercents({'Подписки': 7745, 'Транспорт': 560, 'Еда': 475});
    expect(r.values.fold(0, (s, v) => s + v), 100);
    expect(r['Подписки'], 88);
  });
}
