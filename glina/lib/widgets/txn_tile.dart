import 'package:flutter/material.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/theme/cat_icons.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/cat_bubble.dart';

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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
    final g = context.g;

    final Widget leading;
    final Color titleColor;
    final String title;
    final String? subtitle;
    final int shown;
    final Color amountColor;

    if (txn.isTransfer) {
      final toPiggy = txn.kind == TxnKind.toPiggy;
      if (piggyView) {
        leading = Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Glina.tint(g.accent, g.surf),
            shape: BoxShape.circle,
          ),
          child: Icon(
            toPiggy ? Icons.south_rounded : Icons.north_rounded,
            size: 16,
            color: g.accentText,
          ),
        );
        title = toPiggy ? 'Положил' : 'Снял';
        subtitle = [
          formatDay(txn.date),
          if (txn.note.isNotEmpty) txn.note,
        ].join(' · ');
        shown = txn.piggyDelta;
        titleColor = g.ink;
        amountColor = toPiggy ? g.accentText : g.ink;
      } else {
        leading = Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: g.surf2, shape: BoxShape.circle),
          child: CatIcon('swap', color: g.ink3, size: 17),
        );
        title = toPiggy ? 'В копилку' : 'Из копилки';
        subtitle = [
          if (txn.note.isNotEmpty) txn.note,
          _hm(txn.date),
        ].join(' · ');
        shown = txn.handDelta;
        titleColor = g.ink2;
        amountColor = g.ink3;
      }
    } else {
      final cat = findCategory(txn.category, txn.isIncome);
      leading = CatBubble(cat);
      title = cat.name;
      subtitle = [if (txn.note.isNotEmpty) txn.note, _hm(txn.date)].join(' · ');
      shown = txn.handDelta;
      titleColor = g.ink;
      amountColor = txn.isIncome ? g.pos : g.ink;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Dismissible(
        key: ValueKey(txn.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async => canDelete(),
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: g.accent,
          child: Icon(Icons.delete_outline_rounded, color: g.onAccent),
        ),
        child: Material(
          color: g.surf.withValues(alpha: 0.9),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    leading,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: golos(
                              15,
                              700,
                              color: titleColor,
                              height: 1.2,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: golos(
                                12,
                                500,
                                color: g.ink3,
                                height: 1.25,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatMoney(shown, sign: true),
                      style: literata(16, w: 600, color: amountColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
