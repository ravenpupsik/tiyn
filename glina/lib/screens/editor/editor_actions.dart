import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/editor/transfer_editor.dart';
import 'package:money_app/screens/editor/txn_editor.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/glass_sheet.dart';

Future<void> openTxnEditor(
  BuildContext context,
  Wallet wallet, [
  Txn? existing,
]) async {
  if (existing != null && existing.isTransfer) {
    return openTransferEditor(context, wallet, existing: existing);
  }
  final result = await showGlassSheet<Txn>(
    context,
    TxnEditor(
      existing: existing,
      lastExpense: wallet.lastExpenseCat,
      lastIncome: wallet.lastIncomeCat,
    ),
  );
  if (result == null || !context.mounted) return;
  final block = wallet.editBlock(existing, result);
  if (block != null) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Не сохранил. $block')));
    return;
  }
  wallet.upsert(result);
  wallet.rememberCategory(result);
}

Future<void> openTransferEditor(
  BuildContext context,
  Wallet wallet, {
  Txn? existing,
  bool toPiggy = true,
}) async {
  final result = await showGlassSheet<Txn>(
    context,
    TransferEditor(wallet: wallet, existing: existing, toPiggy: toPiggy),
  );
  if (result != null) wallet.upsert(result);
}

bool confirmDelete(BuildContext context, Wallet wallet, Txn t) {
  final block = wallet.removeBlock(t);
  if (block == null) return true;
  HapticFeedback.heavyImpact();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(block)));
  return false;
}

void deleteWithUndo(BuildContext context, Wallet wallet, Txn t) {
  final index = wallet.remove(t);
  final what = t.isTransfer
      ? (t.kind == TxnKind.toPiggy ? 'перевод в копилку' : 'перевод из копилки')
      : formatMoney(t.amount);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          t.isTransfer
              ? 'Удалён $what: ${formatMoney(t.amount)}'
              : 'Удалено: $what',
        ),
        action: SnackBarAction(
          label: 'Вернуть',
          onPressed: () => wallet.restore(t, index),
        ),
      ),
    );
}
