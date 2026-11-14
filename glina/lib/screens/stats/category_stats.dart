import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/period.dart';
import 'package:money_app/data/txn.dart';

/// Only spending counts (see isSpending): income and piggy-bank transfers are
/// excluded; entries without a category go to "Другое".
List<MapEntry<Category, int>> expensesByCategory(
  List<Txn> items,
  StatPeriod period,
) {
  final sums = <String, int>{};
  for (final t in spendingIn(items, period)) {
    final name = findCategory(t.category, false).name;
    sums[name] = (sums[name] ?? 0) + t.amount;
  }
  final list =
      sums.entries
          .map((e) => MapEntry(findCategory(e.key, false), e.value))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  return list;
}

/// Percentages that always sum to exactly 100 (largest remainder method): round
/// down, then give the missing units to the largest fractional parts.
Map<String, int> roundPercents(Map<String, int> values) {
  final total = values.values.fold(0, (s, v) => s + v);
  if (total == 0) return {for (final k in values.keys) k: 0};
  final floor = <String, int>{};
  final rest = <String, double>{};
  values.forEach((k, v) {
    final exact = v * 100 / total;
    floor[k] = exact.floor();
    rest[k] = exact - exact.floor();
  });
  var left = 100 - floor.values.fold(0, (s, v) => s + v);
  final order = rest.keys.toList()
    ..sort((a, b) => rest[b]!.compareTo(rest[a]!));
  for (final k in order) {
    if (left <= 0) break;
    floor[k] = floor[k]! + 1;
    left--;
  }
  return floor;
}

Color ringColor(Category c, bool dark) => c.forDark(dark);
