import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_app/app.dart';
import 'package:money_app/data/plan.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';

void main() {
  test('Планы: сумма, свободно, сортировка и JSON', () {
    final w = Wallet();
    w.items = [
      Txn(
        id: 'i',
        amount: 40000,
        kind: TxnKind.income,
        category: 'Стипендия',
        note: '',
        date: DateTime(2026, 11, 1),
      ),
    ];
    w.plans = [
      const Plan(id: '2', title: 'Подарок', amount: 5000),
      Plan(
        id: '1',
        title: 'Зубной',
        amount: 15000,
        category: 'Другое',
        due: DateTime(2026, 11, 20),
      ),
    ]..sort(Plan.compare);
    expect(w.planned, 20000);
    expect(w.free, 20000);
    expect(w.plans.first.title, 'Зубной'); // с датой выше
    final back = Plan.fromJson(
      jsonDecode(jsonEncode(w.plans.first.toJson())) as Map<String, dynamic>,
    );
    expect(back.due, DateTime(2026, 11, 20));
    expect(back.amount, 15000);
    expect(const Plan(id: 'x', title: '', amount: 1).displayTitle, 'План');
  });

  testWidgets('План: добавить, видно «Свободно», оплатить', (tester) async {
    SharedPreferences.setMockInitialValues({
      'transactions': jsonEncode([
        Txn(
          id: 'i',
          amount: 39220,
          kind: TxnKind.income,
          category: 'Стипендия',
          note: '',
          date: DateTime.now(),
        ).toJson(),
      ]),
    });
    await tester.pumpWidget(const TiynApp());
    await tester.pumpAndSettle();

    expect(find.text('Планы'), findsOneWidget); // вкладка в плавающей панели
    expect(find.textContaining('Свободно'), findsNothing);

    await tester.tap(find.text('Планы'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить план'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '15000');
    await tester.enterText(find.byType(TextField).at(1), 'Зубной');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Запланировать'));
    await tester.pumpAndSettle();

    expect(find.text('Зубной'), findsOneWidget);
    expect(find.text('24 220 ₸'), findsOneWidget); // свободно

    await tester.tap(find.text('Оплачено'));
    await tester.pumpAndSettle();
    expect(find.text('Зубной'), findsNothing);

    await tester.tap(find.text('Главная'));
    await tester.pumpAndSettle();
    expect(find.text('24 220 ₸'), findsOneWidget); // на руках после оплаты
    expect(find.textContaining('Свободно'), findsNothing);
  });
}
