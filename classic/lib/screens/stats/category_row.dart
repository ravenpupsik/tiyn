import 'package:flutter/material.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/screens/stats/category_stats.dart';
import 'package:money_app/utils/format.dart';

class CategoryRow extends StatelessWidget {
  final Category category;
  final int sum, prev;
  final int percent;
  final bool compareEnabled;
  final VoidCallback onTap;
  const CategoryRow({
    super.key,
    required this.category,
    required this.sum,
    required this.percent,
    required this.prev,
    required this.compareEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.5);
    final diff = sum - prev;

    final Widget? compare;
    if (!compareEnabled) {
      compare = null;
    } else if (prev == 0) {
      compare = Text(
        'в прошлом месяце не было',
        style: TextStyle(color: muted, fontSize: 13),
      );
    } else if (diff == 0) {
      compare = Text(
        'как в прошлом месяце',
        style: TextStyle(color: muted, fontSize: 13),
      );
    } else {
      final up = diff > 0;
      final c = cs.onSurface.withValues(alpha: 0.6);
      compare = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: c,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              '${formatMoney(diff.abs())} к прошлому месяцу',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                category.icon,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.72),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  ?compare,
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(sum),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ringColor(category),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      percent < 1 ? '<1%' : '$percent%',
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
