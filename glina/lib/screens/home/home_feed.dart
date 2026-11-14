import 'package:flutter/material.dart';

import 'package:money_app/data/period.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/editor/editor_actions.dart';
import 'package:money_app/screens/home/balance_card.dart';
import 'package:money_app/screens/home/home_header.dart';
import 'package:money_app/screens/home/quick_input.dart';
import 'package:money_app/theme/cat_icons.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/day_bars.dart';
import 'package:money_app/widgets/day_card.dart';
import 'package:money_app/widgets/group_title.dart';

class HomeFeed extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onOpenPiggy, onOpenSettings, onOpenStats, onOpenPlans;
  const HomeFeed({
    super.key,
    required this.wallet,
    required this.onOpenPiggy,
    required this.onOpenSettings,
    required this.onOpenStats,
    required this.onOpenPlans,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final now = DateTime.now();
    if (wallet.loading) return const SizedBox.shrink();
    final items = wallet.items;
    final groups = <DateTime, List<Txn>>{};
    for (final t in items) {
      groups.putIfAbsent(dateOnly(t.date), () => []).add(t);
    }
    final weekPeriod = StatPeriod.week(now);
    final weekDays = spendingByDay(items, weekPeriod);
    final today = dateOnly(now);
    final days = [
      for (final e in weekDays.entries)
        DayBarData(date: e.key, amount: e.value, isToday: e.key == today),
    ];
    final week = weekDays.values.fold(0, (s, v) => s + v);

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(
            child: HomeHeader(now: now, onSettings: onOpenSettings),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: BalanceCard(
              balance: wallet.onHand,
              free: wallet.plans.isEmpty ? null : wallet.free,
              week: week,
              days: days,
              onFreeTap: onOpenPlans,
              onWeekTap: onOpenStats,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: QuickInput(wallet: wallet, onOpenPiggy: onOpenPiggy),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: const Alignment(0, -0.3),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CatIcon('wallet', color: g.ink2, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'Пока пусто.\nНажми «+» и внеси первую операцию.',
                      textAlign: TextAlign.center,
                      style: golos(14, 500, color: g.ink2, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          for (final (i, entry) in groups.entries.indexed) ...[
            SliverToBoxAdapter(
              child: GroupTitle(
                formatDayHeader(entry.key, now: now),
                // Day total counts expenses only; a day with only income shows
                // no sum.
                sum: hasSpending(entry.value) ? daySpending(entry.value) : null,
                top: i == 0 ? 16 : 20,
              ),
            ),
            SliverToBoxAdapter(
              child: DayCard(
                items: entry.value,
                onTap: (t) => openTxnEditor(context, wallet, t),
                onDelete: (t) => deleteWithUndo(context, wallet, t),
                canDelete: (t) => confirmDelete(context, wallet, t),
              ),
            ),
          ],
        // 150 dp of bottom padding lets the last entry scroll above the
        // floating bar and the "+" button (plus the system gesture bar).
        SliverToBoxAdapter(
          child: SizedBox(
            height: homeBottomPad + MediaQuery.viewPaddingOf(context).bottom,
          ),
        ),
      ],
    );
  }
}

const homeBottomPad = 150.0;
