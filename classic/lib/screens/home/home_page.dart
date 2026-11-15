import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/period.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/editor/editor_actions.dart';
import 'package:money_app/screens/home/balance_card.dart';
import 'package:money_app/screens/home/piggy_pill.dart';
import 'package:money_app/screens/home/plans_pill.dart';
import 'package:money_app/screens/home/tab_bar.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/screens/piggy/piggy_page.dart';
import 'package:money_app/screens/plans/plans_page.dart';
import 'package:money_app/screens/settings/backup_snacks.dart';
import 'package:money_app/screens/settings/settings_page.dart';
import 'package:money_app/screens/stats/stats_page.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/widgets/day_card.dart';
import 'package:money_app/widgets/fade_route.dart';
import 'package:money_app/widgets/group_title.dart';
import 'package:money_app/widgets/pressable.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _wallet = Wallet();
  int _tab = 0;
  int _statsVisit = 0;

  void _goTab(int i) {
    if (_tab == i) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab = i;
      if (i == 1) _statsVisit++;
    });
  }

  @override
  void initState() {
    super.initState();
    _wallet.load();
    Reminder.openAdd.addListener(_openAddFromNotification);
    if (Reminder.launchedFromTap) {
      Reminder.launchedFromTap = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openAddFromNotification(),
      );
    }
  }

  @override
  void dispose() {
    Reminder.openAdd.removeListener(_openAddFromNotification);
    _wallet.dispose();
    super.dispose();
  }

  void _openAddFromNotification() {
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => _tab = 0);
    openTxnEditor(context, _wallet);
  }

  Future<void> _openSettings() async {
    final restored = await Navigator.of(context)
        .push<bool>(fadeRoute<bool>(SettingsPage(wallet: _wallet)));
    if (restored == true && mounted) showRestoredSnack(context, _wallet);
  }

  void _openPiggy() =>
      Navigator.of(context).push(fadeRoute(PiggyPage(wallet: _wallet)));

  void _openStats() => _goTab(1);

  void _openPlans() => _goTab(2);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    // Android Back returns to the home tab first.
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayFor(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              const Positioned.fill(child: Backdrop()),
              IndexedStack(
                index: _tab,
                children: [
                  PauseBackdropOnScroll(
                    child: ListenableBuilder(
                      listenable: _wallet,
                      builder: (context, _) {
                        if (_wallet.loading) {
                          return const SizedBox.shrink();
                        }
                        final items = _wallet.items;
                        final groups = <DateTime, List<Txn>>{};
                        for (final t in items) {
                          groups.putIfAbsent(dateOnly(t.date), () => []).add(t);
                        }
                        final days = groups.entries.toList();
                        return CustomScrollView(
                          slivers: [
                            SliverSafeArea(
                              bottom: false,
                              sliver: SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    12,
                                    20,
                                    0,
                                  ),
                                  child: Row(
                                    children: [
                                      // Hidden while the intro runs: the intro
                                      // logo flies into its place.
                                      ValueListenableBuilder<bool>(
                                        valueListenable: introRunning,
                                        builder: (_, running, child) => Opacity(
                                          opacity: running ? 0 : 1,
                                          child: child,
                                        ),
                                        child: Text(
                                          'Tiyn',
                                          key: logoKey,
                                          style: logoStyle(cs.onSurface),
                                        ),
                                      ),
                                      const Spacer(),
                                      Pressable(
                                        onTap: _openSettings,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Semantics(
                                            button: true,
                                            label: 'Настройки',
                                            excludeSemantics: true,
                                            child: Icon(
                                              Icons.settings_rounded,
                                              size: 20,
                                              color: cs.onSurface.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Pressable(
                                        onTap: _openStats,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.pie_chart_rounded,
                                                size: 16,
                                                color: cs.onSurface.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                monthsNominative[now.month - 1],
                                                style: TextStyle(
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.6),
                                                  fontWeight: FontWeight.w600,
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
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  10,
                                ),
                                child: BalanceCard(
                                  balance: _wallet.onHand,
                                  income: _wallet.monthSum(TxnKind.income),
                                  expense: _wallet.monthSum(TxnKind.expense),
                                  onExpenseTap: _openStats,
                                  free: _wallet.plans.isEmpty
                                      ? null
                                      : _wallet.free,
                                  onFreeTap: _openPlans,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: PiggyPill(
                                  amount: _wallet.piggy,
                                  onTap: _openPiggy,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  0,
                                ),
                                child: PlansPill(
                                  amount: _wallet.planned,
                                  count: _wallet.plans.length,
                                  onTap: _openPlans,
                                ),
                              ),
                            ),
                            if (items.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          size: 56,
                                          color: cs.onSurface.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Пока пусто.\nНажми «+» и внеси первую операцию.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: cs.onSurface.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverList.builder(
                                itemCount: days.length,
                                itemBuilder: (context, i) {
                                  final entry = days[i];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      GroupTitle(
                                        formatDayHeader(entry.key, now: now),
                                        // Day total counts expenses only; a
                                        // day with only income shows no sum.
                                        sum: hasSpending(entry.value)
                                            ? daySpending(entry.value)
                                            : null,
                                      ),
                                      DayCard(
                                        items: entry.value,
                                        onTap: (t) =>
                                            openTxnEditor(context, _wallet, t),
                                        onDelete: (t) =>
                                            deleteWithUndo(context, _wallet, t),
                                        canDelete: (t) =>
                                            confirmDelete(context, _wallet, t),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            // 96 dp of bottom padding lets the last entry
                            // scroll above the tab bar and the "+" button (plus
                            // the system gesture bar).
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    96 +
                                    MediaQuery.viewPaddingOf(context).bottom,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // A new key on every tab entry makes Stats always open on
                  // Month.
                  StatsPage(
                    key: ValueKey(_statsVisit),
                    wallet: _wallet,
                    inTab: true,
                  ),
                  PlansPage(wallet: _wallet, inTab: true),
                ],
              ),
            ],
          ),
          bottomNavigationBar: HomeTabBar(
            index: _tab,
            onSelect: _goTab,
            onAdd: () => openTxnEditor(context, _wallet),
          ),
        ),
      ),
    );
  }
}
