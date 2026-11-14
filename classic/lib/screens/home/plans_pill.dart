import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/money.dart';
import 'package:money_app/widgets/pressable.dart';

String _plansWord(int n) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return '$n план';
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return '$n плана';
  return '$n планов';
}

class PlansPill extends StatelessWidget {
  final int amount, count;
  final VoidCallback onTap;
  const PlansPill({
    super.key,
    required this.amount,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.only(left: 10, right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          color: dark
              ? const Color(0xFF1C1C1F).withValues(alpha: 0.62)
              : Colors.white.withValues(alpha: 0.72),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: kSlateGradient,
                ),
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Запланировано',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    count == 0 ? 'будущие траты' : _plansWord(count),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedMoney(
              value: amount,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: count == 0
                    ? cs.onSurface.withValues(alpha: 0.4)
                    : slateText(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
