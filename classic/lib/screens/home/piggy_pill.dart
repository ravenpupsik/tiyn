import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/money.dart';
import 'package:money_app/widgets/pressable.dart';

class PiggyPill extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;
  const PiggyPill({super.key, required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    final amber = amberText(context);
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
                  colors: kAmberGradient,
                ),
              ),
              child: const Icon(
                Icons.savings_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Копилка',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedMoney(
                  value: amount,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: amber,
                  ),
                ),
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
