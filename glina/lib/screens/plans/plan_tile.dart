import 'package:flutter/material.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/plan.dart';
import 'package:money_app/screens/plans/plan_actions.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/cat_bubble.dart';
import 'package:money_app/widgets/pressable.dart';

class PlanTile extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap, onPay, onDelete;
  const PlanTile({
    super.key,
    required this.plan,
    required this.onTap,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = context.g.ink3;
    final cat = plan.category.isEmpty
        ? null
        : findCategory(plan.category, false);
    final due = plan.due;
    final late = due != null && isOverdue(due);

    return Dismissible(
      key: ValueKey('plan_${plan.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: context.g.accent,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (cat != null)
                CatBubble(cat, diameter: 40)
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.g.line,
                  ),
                  child: Icon(
                    Icons.event_note_outlined,
                    color: context.g.ink2,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(plan.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.g.accentText,
                      ),
                    ),
                    if (due != null)
                      Text(
                        formatDue(due),
                        style: TextStyle(
                          fontSize: 12,
                          color: late ? context.g.accentText : muted,
                          fontWeight: late ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Pressable(
                onTap: onPay,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Glina.tint(context.g.accent, context.g.surf),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: context.g.accentText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Оплачено',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: context.g.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
