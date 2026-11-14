import 'package:flutter/material.dart';

import 'package:money_app/data/txn.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/txn_tile.dart';

class DayCard extends StatelessWidget {
  final List<Txn> items;
  final void Function(Txn) onTap;
  final void Function(Txn) onDelete;
  final bool Function(Txn) canDelete;
  final bool piggyView;
  const DayCard({
    super.key,
    required this.items,
    required this.onTap,
    required this.onDelete,
    required this.canDelete,
    this.piggyView = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF1C1C1F).withValues(alpha: 0.62)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 72,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.06),
              ),
            TxnTile(
              txn: items[i],
              piggyView: piggyView,
              onTap: () => onTap(items[i]),
              onDelete: () => onDelete(items[i]),
              canDelete: () => canDelete(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}
