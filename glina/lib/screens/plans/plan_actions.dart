import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/plan.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/plans/plan_editor.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/glass_sheet.dart';

bool isOverdue(DateTime d) {
  final now = DateTime.now();
  return DateTime(
    d.year,
    d.month,
    d.day,
  ).isBefore(DateTime(now.year, now.month, now.day));
}

String formatDue(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
  final base = d.year == now.year
      ? '${d.day} ${monthsGenitive[d.month - 1]}'
      : '${d.day} ${monthsGenitive[d.month - 1]} ${d.year}';
  if (diff < 0) return 'Просрочено, $base';
  if (diff == 0) return 'Сегодня';
  if (diff == 1) return 'Завтра';
  return 'До $base';
}

Future<void> openPlanEditor(
  BuildContext context,
  Wallet wallet, [
  Plan? existing,
]) async {
  final result = await showGlassSheet<Plan>(
    context,
    PlanEditor(existing: existing),
  );
  if (result != null) wallet.upsertPlan(result);
}

void deletePlanWithUndo(BuildContext context, Wallet wallet, Plan p) {
  final index = wallet.removePlan(p);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('План удалён: ${p.displayTitle}'),
        action: SnackBarAction(
          label: 'Вернуть',
          onPressed: () => wallet.restorePlan(p, index),
        ),
      ),
    );
}

void payPlan(BuildContext context, Wallet wallet, Plan p) {
  final txn = Txn(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    amount: p.amount,
    kind: TxnKind.expense,
    category: p.category.isEmpty ? 'Другое' : p.category,
    note: p.title,
    date: DateTime.now(),
  );
  HapticFeedback.mediumImpact();
  wallet.upsert(txn);
  final index = wallet.removePlan(p);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Оплачено: ${p.displayTitle}, ${formatMoney(p.amount)} ушло в расходы.',
        ),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            wallet.remove(txn);
            wallet.restorePlan(p, index);
          },
        ),
      ),
    );
}
