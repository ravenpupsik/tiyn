import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/period.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/stats/category_row.dart';
import 'package:money_app/screens/stats/category_stats.dart';
import 'package:money_app/screens/stats/category_txns_page.dart';
import 'package:money_app/screens/stats/donut_painter.dart';
import 'package:money_app/screens/stats/period_controls.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/widgets/day_bars.dart';
import 'package:money_app/widgets/fade_route.dart';
import 'package:money_app/widgets/frosted_glass.dart';
import 'package:money_app/widgets/money.dart';
import 'package:money_app/widgets/round_icon_button.dart';
import 'package:money_app/widgets/solid_card.dart';

class StatsPage extends StatefulWidget {
  final Wallet wallet;

  /// true: the screen lives in a tab (no Back button, no own background).
  final bool inTab;
  const StatsPage({super.key, required this.wallet, this.inTab = false});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // The chosen period is not stored: Month on every open.
  PeriodKind _kind = PeriodKind.month;
  late DateTime _month;
  StatPeriod? _custom;
  int _dir = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  StatPeriod _periodAt(DateTime now) => switch (_kind) {
    PeriodKind.week => StatPeriod.week(now),
    PeriodKind.month => StatPeriod.month(_month, now),
    PeriodKind.custom =>
      _custom ??
          StatPeriod.custom(DateTime(now.year, now.month, now.day - 6), now),
  };

  DateTime get _firstRecord {
    final items = widget.wallet.items;
    return items.isEmpty ? DateTime.now() : items.last.date;
  }

  DateTime get _firstMonth {
    final d = _firstRecord;
    return widget.wallet.items.isEmpty ? _month : DateTime(d.year, d.month);
  }

  bool get _isCurrent {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shift(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _dir = delta;
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _selectKind(PeriodKind kind) async {
    if (kind == _kind) return;
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _kind = kind;
      _dir = 0;
      if (kind == PeriodKind.month) _month = DateTime(now.year, now.month);
    });
    // The first tap on Period opens the date picker right away while the last 7
    // days are shown.
    if (kind == PeriodKind.custom && _custom == null) {
      setState(() => _custom = _periodAt(now));
      await _pickCustom();
    }
  }

  Future<void> _pickCustom() async {
    final picked = await pickStatPeriod(
      context,
      initial: _periodAt(DateTime.now()),
      firstRecord: _firstRecord,
    );
    if (picked != null && mounted) setState(() => _custom = picked);
  }

  String _periodTitle(StatPeriod p) => switch (p.kind) {
    PeriodKind.week => '7 дней',
    PeriodKind.month => formatMonth(_month),
    PeriodKind.custom => periodLabel(p),
  };

  void _openCategory(Category cat, StatPeriod period) {
    Navigator.of(context).push(
      fadeRoute(
        CategoryTxnsPage(
          wallet: widget.wallet,
          category: cat,
          period: period,
          title: _periodTitle(period),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (!widget.inTab) const Positioned.fill(child: Backdrop()),
            PauseBackdropOnScroll(
              child: ListenableBuilder(
                listenable: widget.wallet,
                builder: (context, _) {
                  final items = widget.wallet.items;
                  final now = DateTime.now();
                  final period = _periodAt(now);
                  final isMonth = _kind == PeriodKind.month;
                  final isWeek = _kind == PeriodKind.week;
                  final cats = expensesByCategory(items, period);
                  final prev = <String, int>{};
                  if (isMonth) {
                    final prevMonth = StatPeriod.month(
                      DateTime(_month.year, _month.month - 1),
                      now,
                    );
                    for (final e in expensesByCategory(items, prevMonth)) {
                      prev[e.key.name] = e.value;
                    }
                  }
                  final total = cats.fold(0, (s, e) => s + e.value);
                  final avg = period.average(total);
                  final canBack = _month.isAfter(_firstMonth);
                  final pct = roundPercents({
                    for (final e in cats) e.key.name: e.value,
                  });
                  final today = dateOnly(now);

                  return CustomScrollView(
                    slivers: [
                      SliverSafeArea(
                        bottom: false,
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(
                              children: [
                                if (!widget.inTab) ...[
                                  RoundIconButton(
                                    icon: Icons.arrow_back_rounded,
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  const SizedBox(width: 12),
                                ] else
                                  const SizedBox(width: 4),
                                Text(
                                  'Статистика',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                          child: PeriodChips(
                            selected: _kind,
                            onSelect: _selectKind,
                          ),
                        ),
                      ),
                      if (_kind == PeriodKind.custom)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Center(
                              child: PeriodPill(
                                label: periodLabel(period, now: now),
                                onTap: _pickCustom,
                              ),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: FrostedGlass(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              12,
                              12,
                              isWeek ? 16 : 20,
                            ),
                            child: Column(
                              children: [
                                if (isMonth)
                                  Row(
                                    children: [
                                      _MonthArrow(
                                        icon: Icons.chevron_left_rounded,
                                        enabled: canBack,
                                        onTap: () => _shift(-1),
                                      ),
                                      Expanded(
                                        child: AnimatedSwitcher(
                                          duration: kFast,
                                          transitionBuilder: (child, anim) =>
                                              FadeTransition(
                                                opacity: anim,
                                                child: SlideTransition(
                                                  position: Tween(
                                                    begin: Offset(
                                                      0.15 * _dir,
                                                      0,
                                                    ),
                                                    end: Offset.zero,
                                                  ).animate(anim),
                                                  child: child,
                                                ),
                                              ),
                                          child: Text(
                                            formatMonth(_month),
                                            key: ValueKey(_month),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _MonthArrow(
                                        icon: Icons.chevron_right_rounded,
                                        enabled: !_isCurrent,
                                        onTap: () => _shift(1),
                                      ),
                                    ],
                                  ),
                                SizedBox(height: isMonth ? 12 : 8),
                                SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(period),
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 750),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, t, _) => CustomPaint(
                                      painter: DonutPainter(
                                        parts: [
                                          for (final e in cats)
                                            (ringColor(e.key), e.value),
                                        ],
                                        progress: t,
                                        track: cs.onSurface.withValues(
                                          alpha: dark ? 0.08 : 0.06,
                                        ),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 30,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Расходы',
                                                style: TextStyle(
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.55),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              DotMoney(
                                                value: total,
                                                size: 36,
                                                color: cs.onSurface,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  total == 0
                                      ? switch (_kind) {
                                          PeriodKind.month =>
                                            'В этом месяце трат нет',
                                          PeriodKind.week =>
                                            'За 7 дней трат нет',
                                          PeriodKind.custom =>
                                            'За этот период трат нет',
                                        }
                                      : 'В среднем ${formatMoney(avg)} в день',
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isWeek) ...[
                                  const SizedBox(height: 20),
                                  DayBars(
                                    todayColor: accentOf(context),
                                    days: [
                                      for (final e in spendingByDay(
                                        items,
                                        period,
                                      ).entries)
                                        DayBarData(
                                          date: e.key,
                                          amount: e.value,
                                          isToday: e.key == today,
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (cats.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SolidCard(
                              children: [
                                for (final e in cats)
                                  CategoryRow(
                                    category: e.key,
                                    sum: e.value,
                                    percent: pct[e.key.name]!,
                                    prev: prev[e.key.name] ?? 0,
                                    compareEnabled: isMonth && prev.isNotEmpty,
                                    onTap: () => _openCategory(e.key, period),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: widget.inTab ? 130 : 40),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _MonthArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.25,
        duration: kFast,
        child: RoundIconButton(icon: icon, onTap: onTap),
      ),
    );
  }
}
