import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/services/reminder.dart';

Txn t(DateTime d) => Txn(
  id: '1',
  amount: 100,
  kind: TxnKind.expense,
  category: 'Еда',
  note: '',
  date: d,
);

void main() {
  setUp(() => Reminder.settings.value = (true, 21, 0));

  test('днём без записей: напоминание сегодня и дальше', () {
    final now = DateTime(2026, 11, 3, 14, 0);
    final days = Reminder.plannedDays([], now);
    expect(days.first, 0);
    expect(days.length, 14);
  });

  test('есть запись за сегодня: сегодня молчим', () {
    final now = DateTime(2026, 11, 3, 14, 0);
    final days = Reminder.plannedDays([t(DateTime(2026, 11, 3, 9))], now);
    expect(days.first, 1);
  });

  test('после 21:00 сегодняшнее уже не ставим', () {
    final now = DateTime(2026, 11, 3, 22, 0);
    expect(Reminder.plannedDays([], now).first, 1);
  });

  test('вчерашняя запись не мешает сегодняшнему', () {
    final now = DateTime(2026, 11, 3, 14, 0);
    expect(Reminder.plannedDays([t(DateTime(2026, 11, 2, 20))], now).first, 0);
  });
}
