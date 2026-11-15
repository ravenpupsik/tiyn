import 'package:money_app/data/category.dart';

/// Piggy-bank transfers are neither income nor expense: money just moves.
enum TxnKind { expense, income, toPiggy, fromPiggy }

class Txn {
  final String id;
  final int amount;
  final TxnKind kind;
  final String category;
  final String note;
  final DateTime date;

  Txn({
    required this.id,
    required this.amount,
    required this.kind,
    required this.category,
    required this.note,
    required this.date,
  });

  bool get isIncome => kind == TxnKind.income;
  bool get isTransfer => kind == TxnKind.toPiggy || kind == TxnKind.fromPiggy;

  int get handDelta => switch (kind) {
    TxnKind.income || TxnKind.fromPiggy => amount,
    TxnKind.expense || TxnKind.toPiggy => -amount,
  };

  int get piggyDelta => switch (kind) {
    TxnKind.toPiggy => amount,
    TxnKind.fromPiggy => -amount,
    _ => 0,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'kind': kind.name,
    'isIncome': isIncome,
    'category': category,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory Txn.fromJson(Map<String, dynamic> j) {
    final rawKind = j['kind'] as String?;
    final kind = TxnKind.values.firstWhere(
      (k) => k.name == rawKind,
      // Old entries without a `kind` field.
      orElse: () =>
          (j['isIncome'] as bool? ?? false) ? TxnKind.income : TxnKind.expense,
    );
    return Txn(
      id: j['id'] as String,
      amount: j['amount'] as int,
      kind: kind,
      category: canonicalCategory((j['category'] ?? '') as String),
      note: (j['note'] ?? '') as String,
      date: DateTime.parse(j['date'] as String),
    );
  }
}
