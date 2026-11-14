import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/day_bars.dart';
import 'package:money_app/widgets/money.dart';
import 'package:money_app/widgets/surf_panel.dart';

class BalanceCard extends StatelessWidget {
  final int balance;
  final int? free;
  final int week;
  final List<DayBarData> days;
  final VoidCallback onFreeTap, onWeekTap;
  const BalanceCard({
    super.key,
    required this.balance,
    required this.free,
    required this.week,
    required this.days,
    required this.onFreeTap,
    required this.onWeekTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final bad = free != null && free! < 0;
    return Container(
      decoration: BoxDecoration(
        color: g.surf,
        borderRadius: BorderRadius.circular(28),
        boxShadow: glinaShadow(g),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.95, -1.0),
                    radius: 1.1,
                    colors: [
                      g.accent.withValues(alpha: g.dark ? 0.10 : 0.09),
                      g.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 18,
                    child: Text(
                      'На руках',
                      style: golos(13, 600, color: g.ink2, height: 1.2),
                    ),
                  ),
                  SizedBox(
                    height: 46,
                    child: BigMoney(value: balance, size: 38, color: g.ink),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 26,
                    child: Row(
                      children: [
                        if (free != null)
                          Flexible(
                            child: _Pill(
                              text: bad
                                  ? 'Не хватает на планы ${formatMoney(-free!)}'
                                  : 'Свободно ${formatMoney(free!)}',
                              fill: bad
                                  ? Glina.tint(g.accent, g.surf)
                                  : g.accent,
                              fg: bad ? g.accentText : g.onAccent,
                              onTap: onFreeTap,
                            ),
                          ),
                        if (free != null) const SizedBox(width: 8),
                        _Pill(
                          text: 'Неделя ${formatMoney(-week)}',
                          fill: g.surf2,
                          fg: g.ink,
                          onTap: onWeekTap,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _WeekBars(days: days),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color fill, fg;
  final VoidCallback onTap;
  const _Pill({
    required this.text,
    required this.fill,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(13),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, style: golos(12, 700, color: fg, height: 1.2)),
        ),
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  final List<DayBarData> days;
  const _WeekBars({required this.days});

  static const maxBar = 30.0;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final maxAmount = days.fold(0, (m, d) => d.amount > m ? d.amount : m);
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: maxAmount > 0 ? maxBar : 6,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 6,
                      height: d.amount <= 0 || maxAmount <= 0
                          ? 4
                          : (d.amount / maxAmount * maxBar).clamp(6.0, maxBar),
                      decoration: BoxDecoration(
                        color: d.isToday
                            ? g.accent
                            : g.ink.withValues(alpha: g.dark ? 0.40 : 0.38),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 12,
                  child: Text(
                    weekdayShort(d.date),
                    maxLines: 1,
                    style: golos(
                      10,
                      700,
                      color: d.isToday ? g.accent : g.ink3,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
