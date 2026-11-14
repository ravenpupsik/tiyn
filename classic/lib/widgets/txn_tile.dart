import 'package:flutter/material.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

class TxnTile extends StatelessWidget {
  final Txn txn;
  final bool piggyView;
  final VoidCallback onTap, onDelete;
  final bool Function() canDelete;
  const TxnTile({
    super.key,
    required this.txn,
    required this.onTap,
    required this.onDelete,
    required this.canDelete,
    this.piggyView = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.5);

    final IconData icon;
    final Color iconColor;
    final String title;
    final String? subtitle;
    final int shown;
    final Color amountColor;

    if (txn.isTransfer) {
      final toPiggy = txn.kind == TxnKind.toPiggy;
      if (piggyView) {
        icon = toPiggy ? Icons.south_rounded : Icons.north_rounded;
        iconColor = amberText(context);
        title = toPiggy ? 'Положил' : 'Снял';
        subtitle = [
          formatDay(txn.date),
          if (txn.note.isNotEmpty) txn.note,
        ].join(' · ');
        shown = txn.piggyDelta;
        amountColor = toPiggy ? amberText(context) : cs.onSurface;
      } else {
        icon = Icons.swap_vert_rounded;
        iconColor = cs.onSurface.withValues(alpha: 0.5);
        title = toPiggy ? 'В копилку' : 'Из копилки';
        subtitle = txn.note.isEmpty ? null : txn.note;
        shown = txn.handDelta;
        amountColor = cs.onSurface.withValues(alpha: 0.5);
      }
    } else {
      final cat = findCategory(txn.category, txn.isIncome);
      icon = cat.icon;
      iconColor = cs.onSurface.withValues(alpha: 0.72);
      title = cat.name;
      subtitle = txn.note.isEmpty ? null : txn.note;
      shown = txn.handDelta;
      amountColor = cs.onSurface;
    }

    return Dismissible(
      key: ValueKey(txn.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => canDelete(),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: kRed,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: txn.isTransfer && !piggyView
                            ? cs.onSurface.withValues(alpha: 0.6)
                            : cs.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                  ],
                ),
              ),
              Text(
                formatMoney(shown, sign: true),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
