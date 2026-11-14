import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/frosted_glass.dart';
import 'package:money_app/widgets/money.dart';
import 'package:money_app/widgets/pressable.dart';

class BalanceCard extends StatelessWidget {
  final int balance, income, expense;
  final VoidCallback onExpenseTap;
  final int? free;
  final VoidCallback onFreeTap;
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    required this.onExpenseTap,
    required this.free,
    required this.onFreeTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FrostedGlass(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'На руках',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: DotMoney(value: balance, size: 44, color: cs.onSurface),
          ),
          AnimatedSize(
            duration: kFast,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: free == null
                ? const SizedBox(width: double.infinity)
                : Pressable(
                    onTap: onFreeTap,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: _FreeLine(free: free!),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_downward_rounded,
                  color: cs.onSurface.withValues(alpha: 0.7),
                  label: 'Доходы',
                  value: formatMoney(income),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Pressable(
                  onTap: onExpenseTap,
                  child: _MiniStat(
                    icon: Icons.arrow_upward_rounded,
                    color: cs.onSurface.withValues(alpha: 0.7),
                    label: 'Расходы',
                    value: formatMoney(expense),
                    showChevron: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final bool showChevron;
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: isDark(context) ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
        ],
      ),
    );
  }
}

class _FreeLine extends StatelessWidget {
  final int free;
  const _FreeLine({required this.free});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bad = free < 0;
    final color = bad ? kDanger : slateText(context);
    return Row(
      children: [
        Icon(
          bad ? Icons.error_outline_rounded : Icons.event_available_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          bad ? 'Не хватает на планы ' : 'Свободно ',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        AnimatedMoney(
          value: bad ? -free : free,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
