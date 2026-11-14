import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Txn tr(String id, int amount, TxnKind kind) => Txn(
  id: id,
  amount: amount,
  kind: kind,
  category: '',
  note: '',
  date: DateTime(2026, 10, 31, 1, int.parse(id)),
);

void main() {
  test('Положил 200, снял 200: копилка 0, на руках как было', () async {
    SharedPreferences.setMockInitialValues({});
    final w = Wallet();
    await w.load();
    w.upsert(
      Txn(
        id: '0',
        amount: 39220,
        kind: TxnKind.income,
        category: 'Стипендия',
        note: '',
        date: DateTime(2026, 10, 1),
      ),
    );
    final dep = tr('1', 200, TxnKind.toPiggy);
    final out = tr('2', 200, TxnKind.fromPiggy);
    w.upsert(dep);
    w.upsert(out);
    expect(w.piggy, 0);
    expect(w.onHand, 39220);

    // Пополнение удалить нельзя, пока есть снятие.
    expect(w.canRemove(dep), isFalse);
    // Снятие удалить можно, после этого и пополнение.
    expect(w.canRemove(out), isTrue);
    w.remove(out);
    expect(w.canRemove(dep), isTrue);
    w.remove(dep);
    expect(w.piggy, 0);
    expect(w.onHand, 39220);
  });

  test('Доход 50к, потратил 10к: доход удалить нельзя', () async {
    SharedPreferences.setMockInitialValues({});
    final w = Wallet();
    await w.load();
    final inc = tr('1', 50000, TxnKind.income);
    final exp = tr('2', 10000, TxnKind.expense);
    w.upsert(inc);
    w.upsert(exp);
    expect(w.canRemove(inc), isFalse);
    expect(w.canRemove(exp), isTrue);
    // Уменьшить доход до 5к тоже нельзя, до 20к можно.
    expect(w.editBlock(inc, tr('1', 5000, TxnKind.income)), isNotNull);
    expect(w.editBlock(inc, tr('1', 20000, TxnKind.income)), isNull);
    w.remove(exp);
    expect(w.canRemove(inc), isTrue);
  });

  test('Снял 50к из копилки, потратил 10к: снятие удалить нельзя', () async {
    SharedPreferences.setMockInitialValues({'piggy_start': 50000});
    final w = Wallet();
    await w.load();
    final out = tr('1', 50000, TxnKind.fromPiggy);
    w.upsert(out);
    w.upsert(tr('2', 10000, TxnKind.expense));
    expect(w.onHand, 40000);
    expect(w.canRemove(out), isFalse);
  });
}
