import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/data/plan.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/services/tiyn_home_widget.dart';
import 'package:money_app/utils/format.dart';

/// All app money: entries, the piggy-bank starting amount and plans.
class Wallet extends ChangeNotifier {
  static const _key = 'transactions';
  static const _piggyStartKey = 'piggy_start';
  static const _plansKey = 'plans';
  static const _lastExpenseKey = 'last_cat_expense';
  static const _lastIncomeKey = 'last_cat_income';

  List<Txn> items = [];
  List<Plan> plans = [];
  int piggyStart = 0;
  bool loading = true;

  String? lastExpenseCat, lastIncomeCat;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Reloading (also after a restore): anything missing from prefs resets to
    // defaults.
    final raw = prefs.getString(_key);
    items = raw == null
        ? []
        : (jsonDecode(raw) as List)
              .map((e) => Txn.fromJson(e as Map<String, dynamic>))
              .toList();
    _sort();
    piggyStart = prefs.getInt(_piggyStartKey) ?? 0;
    lastExpenseCat = prefs.getString(_lastExpenseKey);
    lastIncomeCat = prefs.getString(_lastIncomeKey);
    final rawPlans = prefs.getString(_plansKey);
    plans = rawPlans == null
        ? []
        : ((jsonDecode(rawPlans) as List)
              .map((e) => Plan.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort(Plan.compare));
    loading = false;
    notifyListeners();
    Reminder.reschedule(items);
    TiynHomeWidget.update(this);
  }

  Future<void> rememberCategory(Txn t) async {
    if (t.kind == TxnKind.expense) {
      lastExpenseCat = t.category;
    } else if (t.kind == TxnKind.income) {
      lastIncomeCat = t.category;
    } else {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (lastExpenseCat != null) {
      await prefs.setString(_lastExpenseKey, lastExpenseCat!);
    }
    if (lastIncomeCat != null) {
      await prefs.setString(_lastIncomeKey, lastIncomeCat!);
    }
  }

  void _sort() => items.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    await prefs.setInt(_piggyStartKey, piggyStart);
    await prefs.setString(
      _plansKey,
      jsonEncode(plans.map((e) => e.toJson()).toList()),
    );
    Reminder.reschedule(items);
    TiynHomeWidget.update(this);
  }

  int get onHand => items.fold(0, (s, t) => s + t.handDelta);
  int get piggy => items.fold(piggyStart, (s, t) => s + t.piggyDelta);
  List<Txn> get transfers => items.where((t) => t.isTransfer).toList();

  int monthSum(TxnKind kind) {
    final now = DateTime.now();
    return items
        .where(
          (t) =>
              t.kind == kind &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0, (s, t) => s + t.amount);
  }

  void upsert(Txn t) {
    items.removeWhere((e) => e.id == t.id);
    items.add(t);
    _sort();
    notifyListeners();
    _save();
  }

  /// Why an entry can't be deleted (null if it can). Deletion must not push the
  /// piggy bank or the main balance below zero; deleting expenses is always
  /// allowed.
  String? removeBlock(Txn t) {
    if (t.piggyDelta > 0 && piggy - t.piggyDelta < 0) {
      return 'Копилка уйдёт в минус. Сначала удали снятие, которое было после этого пополнения.';
    }
    if (t.handDelta > 0 && onHand - t.handDelta < 0) {
      final short = formatMoney(t.handDelta - onHand);
      return t.kind == TxnKind.fromPiggy
          ? 'На руках уйдёт в минус на $short. Эти деньги уже потрачены.'
          : 'На руках уйдёт в минус на $short. Из этого дохода уже потрачено, сначала удали расходы.';
    }
    return null;
  }

  bool canRemove(Txn t) => removeBlock(t) == null;

  /// Why an edit can't be saved (null if it can). Only blocks reducing an
  /// income when that pushes the balance below zero.
  String? editBlock(Txn? old, Txn next) {
    final hand = onHand - (old?.handDelta ?? 0) + next.handDelta;
    if (old != null &&
        old.handDelta > 0 &&
        next.handDelta < old.handDelta &&
        hand < 0) {
      return 'На руках уйдёт в минус на ${formatMoney(-hand)}. Из этого дохода уже потрачено.';
    }
    return null;
  }

  int remove(Txn t) {
    final i = items.indexOf(t);
    items.remove(t);
    notifyListeners();
    _save();
    return i;
  }

  void restore(Txn t, int index) {
    items.insert(index.clamp(0, items.length), t);
    _sort();
    notifyListeners();
    _save();
  }

  void setPiggyStart(int v) {
    piggyStart = v;
    notifyListeners();
    _save();
  }

  int get planned => plans.fold(0, (s, p) => s + p.amount);

  int get free => onHand - planned;

  void upsertPlan(Plan p) {
    plans.removeWhere((e) => e.id == p.id);
    plans.add(p);
    plans.sort(Plan.compare);
    notifyListeners();
    _save();
  }

  int removePlan(Plan p) {
    final i = plans.indexWhere((e) => e.id == p.id);
    plans.removeWhere((e) => e.id == p.id);
    notifyListeners();
    _save();
    return i;
  }

  void restorePlan(Plan p, int index) {
    plans.insert(index.clamp(0, plans.length), p);
    plans.sort(Plan.compare);
    notifyListeners();
    _save();
  }
}
