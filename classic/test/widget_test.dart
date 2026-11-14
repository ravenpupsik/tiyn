import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/app.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  breathingEnabled = false; // бесконечная анимация фона мешает pumpAndSettle
  testWidgets('Главный экран открывается', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TiynApp());
    await tester.pumpAndSettle();
    expect(find.text('На руках'), findsOneWidget);
    expect(find.text('Копилка'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('Старые записи читаются, перевод не считается расходом', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'transactions':
          '[{"id":"1","amount":48000,"isIncome":true,"category":"Стипендия","note":"","date":"2026-10-01T10:00:00.000"},'
          '{"id":"2","amount":20000,"kind":"toPiggy","isIncome":false,"category":"","note":"","date":"2026-10-02T10:00:00.000"}]',
      'piggy_start': 100000,
    });
    final w = Wallet();
    await w.load();
    expect(w.onHand, 28000);
    expect(w.piggy, 120000);
    expect(w.monthSum(TxnKind.expense), 0);
  });
}
