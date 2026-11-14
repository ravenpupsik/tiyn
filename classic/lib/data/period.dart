import 'package:money_app/data/txn.dart';

/// Bounds are inclusive, in the phone's local time; the time of day is dropped.
enum PeriodKind { week, month, custom }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Single rule for what counts as spending: only real expenses. Income and
/// piggy-bank transfers are excluded. Planned payments (Plan) are not entries
/// until marked as paid.
bool isSpending(Txn t) => t.kind == TxnKind.expense;

class StatPeriod {
  final PeriodKind kind;

  final DateTime start, end;

  const StatPeriod._(this.kind, this.start, this.end);

  factory StatPeriod.week(DateTime now) {
    final today = dateOnly(now);
    return StatPeriod._(
      PeriodKind.week,
      DateTime(today.year, today.month, today.day - 6),
      today,
    );
  }

  /// The current month runs up to today (the average divides by elapsed days);
  /// past months run to the end of the month.
  factory StatPeriod.month(DateTime month, DateTime now) {
    final today = dateOnly(now);
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final end = last.isAfter(today) ? today : last;
    return StatPeriod._(
      PeriodKind.month,
      first,
      end.isBefore(first) ? first : end,
    );
  }

  factory StatPeriod.custom(DateTime a, DateTime b) {
    final x = dateOnly(a), y = dateOnly(b);
    return x.isAfter(y)
        ? StatPeriod._(PeriodKind.custom, y, x)
        : StatPeriod._(PeriodKind.custom, x, y);
  }

  int get days =>
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;

  bool contains(DateTime d) {
    final x = dateOnly(d);
    return !x.isBefore(start) && !x.isAfter(end);
  }

  List<DateTime> get allDays => [
    for (var i = 0; i < days; i++)
      DateTime(start.year, start.month, start.day + i),
  ];

  int average(int total) => total ~/ days;

  @override
  bool operator ==(Object other) =>
      other is StatPeriod &&
      other.kind == kind &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);
}

List<Txn> spendingIn(Iterable<Txn> items, StatPeriod p) =>
    items.where((t) => isSpending(t) && p.contains(t.date)).toList();

int totalSpending(Iterable<Txn> items, StatPeriod p) =>
    spendingIn(items, p).fold(0, (s, t) => s + t.amount);

/// Has a key for every day of the period (0 if there was no spending).
Map<DateTime, int> spendingByDay(Iterable<Txn> items, StatPeriod p) {
  final map = {for (final d in p.allDays) d: 0};
  for (final t in spendingIn(items, p)) {
    final k = dateOnly(t.date);
    map[k] = (map[k] ?? 0) + t.amount;
  }
  return map;
}

int daySpending(Iterable<Txn> dayItems) =>
    dayItems.where(isSpending).fold(0, (s, t) => s + t.amount);

bool hasSpending(Iterable<Txn> dayItems) => dayItems.any(isSpending);
