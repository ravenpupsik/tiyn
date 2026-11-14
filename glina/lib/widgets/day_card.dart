import 'package:flutter/material.dart';

import 'package:money_app/data/txn.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
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
