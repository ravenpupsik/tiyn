import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/editor/txn_editor.dart';
import 'package:money_app/widgets/glass_sheet.dart';

/// Opens the "+" sheet from a button and puts the result into [out].
Widget host(List<Txn?> out, {String? lastExpense, String? lastIncome}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              final t = await showGlassSheet<Txn>(
                context,
                TxnEditor(lastExpense: lastExpense, lastIncome: lastIncome),
              );
              out.add(t);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Шит «+»: на нуле кнопка неактивна, потом сохраняет трату', (
    tester,
  ) async {
    final out = <Txn?>[];
    await tester.pumpWidget(host(out));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(out, isEmpty); // шит остался открыт

    await tester.enterText(find.byType(TextField).first, '1500');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(out.single!.amount, 1500);
    expect(out.single!.kind, TxnKind.expense);
    expect(out.single!.category, 'Еда'); // первая, пока «последней» нет
  });

  testWidgets('Последняя категория режима выбрана заранее', (tester) async {
    final out = <Txn?>[];
    await tester.pumpWidget(
      host(out, lastExpense: 'Кафе', lastIncome: 'Другое'),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '700');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(out.single!.category, 'Кафе');

    out.clear();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Доход'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '48000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(out.single!.kind, TxnKind.income);
    expect(out.single!.category, 'Другое');
  });

  testWidgets('Доход: только «Стипендия» и «Другое»', (tester) async {
    await tester.pumpWidget(host([]));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Доход'));
    await tester.pumpAndSettle();
    expect(find.text('Стипендия'), findsOneWidget);
    expect(find.text('Другое'), findsOneWidget);
    expect(find.text('Подработка'), findsNothing);
    expect(find.text('Подарок'), findsNothing);
    expect(find.text('Еда'), findsNothing);
  });

  test('Кошелёк помнит последнюю категорию по режимам', () async {
    SharedPreferences.setMockInitialValues({});
    final w = Wallet();
    await w.load();
    Txn t(TxnKind k, String c) => Txn(
      id: c,
      amount: 1,
      kind: k,
      category: c,
      note: '',
      date: DateTime(2026, 11, 1),
    );
    await w.rememberCategory(t(TxnKind.expense, 'Кафе'));
    await w.rememberCategory(t(TxnKind.income, 'Другое'));
    await w.rememberCategory(t(TxnKind.toPiggy, ''));
    final w2 = Wallet();
    await w2.load();
    expect(w2.lastExpenseCat, 'Кафе');
    expect(w2.lastIncomeCat, 'Другое');
  });

  testWidgets('Старый доход «Подработка» читается и открывается в правке', (
    tester,
  ) async {
    final old = Txn(
      id: 'o',
      amount: 5000,
      kind: TxnKind.income,
      category: 'Подработка',
      note: '',
      date: DateTime(2026, 10, 5),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TxnEditor(existing: old, autofocus: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Подработка'), findsOneWidget);
  });
}
