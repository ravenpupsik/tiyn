import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/data/period.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/screens/stats/category_stats.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/day_bars.dart';

Txn tx(
  int amount,
  DateTime d, {
  TxnKind kind = TxnKind.expense,
  String id = '',
}) => Txn(
  id: id.isEmpty ? '$amount${d.microsecondsSinceEpoch}${kind.name}' : id,
  amount: amount,
  kind: kind,
  category: 'Еда',
  note: '',
  date: d,
);

void main() {
  final now = DateTime(2026, 11, 11, 15, 30); // среда

  group('Границы периодов', () {
    test('«7 дней» = сегодня и 6 предыдущих', () {
      final p = StatPeriod.week(now);
      expect(p.start, DateTime(2026, 11, 5));
      expect(p.end, DateTime(2026, 11, 11));
      expect(p.days, 7);
      expect(p.allDays.length, 7);
      expect(p.allDays.last, DateTime(2026, 11, 11));
    });

    test('«7 дней» через границу месяца и года', () {
      final p = StatPeriod.week(DateTime(2026, 1, 3));
      expect(p.start, DateTime(2025, 12, 28));
      expect(p.days, 7);
    });

    test('«Месяц»: с 1-го по сегодня, среднее на прошедшие дни', () {
      final p = StatPeriod.month(DateTime(2026, 11), now);
      expect(p.start, DateTime(2026, 11, 1));
      expect(p.end, DateTime(2026, 11, 11));
      expect(p.days, 11); // 11 нояб. делим на 11, а не на 30
      expect(p.average(2200), 200);
    });

    test('Прошлый месяц считается целиком', () {
      expect(StatPeriod.month(DateTime(2026, 10), now).days, 31);
      expect(StatPeriod.month(DateTime(2026, 9), now).days, 30);
      expect(StatPeriod.month(DateTime(2026, 2), now).days, 28);
    });

    test('«Период» включает оба края; перепутанный порядок чинится', () {
      final p = StatPeriod.custom(
        DateTime(2026, 11, 9, 23),
        DateTime(2026, 11, 3),
      );
      expect(p.start, DateTime(2026, 11, 3));
      expect(p.end, DateTime(2026, 11, 9));
      expect(p.days, 7);
      expect(
        StatPeriod.custom(DateTime(2026, 11, 3), DateTime(2026, 11, 3)).days,
        1,
      );
    });

    test('contains игнорирует время суток', () {
      final p = StatPeriod.custom(DateTime(2026, 11, 3), DateTime(2026, 11, 9));
      expect(p.contains(DateTime(2026, 11, 3, 0, 0)), isTrue);
      expect(p.contains(DateTime(2026, 11, 9, 23, 59)), isTrue);
      expect(p.contains(DateTime(2026, 11, 2, 23, 59)), isFalse);
      expect(p.contains(DateTime(2026, 11, 10)), isFalse);
    });
  });

  group('Что считается тратой', () {
    final d = DateTime(2026, 11, 10, 12);
    final items = [
      tx(678, d, id: 'e'),
      tx(25000, d, kind: TxnKind.income, id: 'i'),
      tx(11000, d, kind: TxnKind.toPiggy, id: 'tp'),
      tx(500, d, kind: TxnKind.fromPiggy, id: 'fp'),
    ];

    test('только расходы: без доходов и переводов в Копилку', () {
      final p = StatPeriod.week(now);
      expect(totalSpending(items, p), 678);
      expect(spendingIn(items, p).single.id, 'e');
    });

    test('сумма дня: «Вчера» 678 + стипендия → только 678', () {
      expect(daySpending(items), 678);
      expect(hasSpending(items), isTrue);
    });

    test('день только с доходами или переводами: суммы нет', () {
      final onlyIncome = [tx(25000, d, kind: TxnKind.income)];
      expect(hasSpending(onlyIncome), isFalse);
      expect(hasSpending([tx(100, d, kind: TxnKind.toPiggy)]), isFalse);
    });

    test('траты вне периода не считаются, края включены', () {
      final p = StatPeriod.week(now); // 5..11 нояб.
      final list = [
        tx(1, DateTime(2026, 11, 4, 23, 59), id: 'a'),
        tx(2, DateTime(2026, 11, 5, 0, 0), id: 'b'),
        tx(4, DateTime(2026, 11, 11, 23, 59), id: 'c'),
        tx(8, DateTime(2026, 11, 12, 0, 1), id: 'd'),
      ];
      expect(totalSpending(list, p), 6);
    });

    test('spendingByDay: ключ на каждый день, пустые дни = 0', () {
      final p = StatPeriod.week(now);
      final m = spendingByDay([
        tx(100, DateTime(2026, 11, 6, 9), id: 'a'),
        tx(50, DateTime(2026, 11, 6, 20), id: 'b'),
        tx(4120, DateTime(2026, 11, 7), id: 'c'),
      ], p);
      expect(m.length, 7);
      expect(m[DateTime(2026, 11, 6)], 150);
      expect(m[DateTime(2026, 11, 7)], 4120);
      expect(m[DateTime(2026, 11, 8)], 0);
      expect(m.keys.last, DateTime(2026, 11, 11));
    });

    test('категории считаются за выбранный период', () {
      final list = [
        tx(300, DateTime(2026, 11, 10), id: 'a'),
        tx(700, DateTime(2026, 10, 20), id: 'b'),
      ];
      final week = expensesByCategory(list, StatPeriod.week(now));
      expect(week.single.value, 300);
      final oct = expensesByCategory(
        list,
        StatPeriod.month(DateTime(2026, 10), now),
      );
      expect(oct.single.value, 700);
    });
  });

  group('Подписи', () {
    test('заголовок дня', () {
      expect(formatDayHeader(DateTime(2026, 11, 11, 8), now: now), 'Сегодня');
      expect(formatDayHeader(DateTime(2026, 11, 10, 23), now: now), 'Вчера');
      expect(formatDayHeader(DateTime(2026, 11, 9), now: now), 'Пн, 9 нояб.');
      expect(
        formatDayHeader(DateTime(2025, 12, 31), now: now),
        'Ср, 31 дек. 2025',
      );
    });

    test('пилюля периода', () {
      expect(
        formatRangeLabel(
          DateTime(2026, 11, 3),
          DateTime(2026, 11, 9),
          now: now,
        ),
        '3 нояб. – 9 нояб.',
      );
      expect(
        formatRangeLabel(
          DateTime(2026, 11, 9),
          DateTime(2026, 11, 9),
          now: now,
        ),
        '9 нояб.',
      );
    });

    test('сумма: пробел-разделитель и минус', () {
      expect(formatMoney(-4120), '−4 120 ₸');
      expect(formatMoney(-1480), '−1 480 ₸');
    });
  });

  test('Высота столбика: максимум 64, минимум 4, пустой день 0', () {
    expect(DayBars.barHeightFor(4120, 4120), 64);
    expect(DayBars.barHeightFor(2060, 4120), 32);
    expect(DayBars.barHeightFor(1, 4120), 4);
    expect(DayBars.barHeightFor(0, 4120), 0);
    expect(DayBars.barHeightFor(0, 0), 0);
  });
}
