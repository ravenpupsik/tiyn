import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/editor/editor_actions.dart';
import 'package:money_app/screens/piggy/piggy_start_sheet.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/widgets/day_card.dart';
import 'package:money_app/widgets/glass_sheet.dart';
import 'package:money_app/widgets/group_title.dart';
import 'package:money_app/widgets/money.dart';
import 'package:money_app/widgets/pressable.dart';
import 'package:money_app/widgets/round_icon_button.dart';

class PiggyPage extends StatelessWidget {
  final Wallet wallet;
  const PiggyPage({super.key, required this.wallet});

  Future<void> _editStart(BuildContext context) async {
    final v = await showGlassSheet<int>(
      context,
      PiggyStartSheet(initial: wallet.piggyStart),
    );
    if (v == null || !context.mounted) return;
    // The starting amount can't be less than what was withdrawn beyond
    // deposits.
    final minStart = wallet.piggyStart - wallet.piggy;
    if (v < minStart) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Минимум ${formatMoney(minStart)}, иначе копилка уйдёт в минус.',
            ),
          ),
        );
      return;
    }
    wallet.setPiggyStart(v);
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
            const Positioned.fill(child: Backdrop()),
            PauseBackdropOnScroll(
              child: ListenableBuilder(
                listenable: wallet,
                builder: (context, _) {
                  final transfers = wallet.transfers;
                  final groups = <String, List<Txn>>{};
                  for (final t in transfers) {
                    groups.putIfAbsent(formatMonth(t.date), () => []).add(t);
                  }
                  final showStartHint =
                      wallet.piggyStart == 0 && transfers.isEmpty;

                  return CustomScrollView(
                    slivers: [
                      SliverSafeArea(
                        bottom: false,
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Row(
                              children: [
                                RoundIconButton(
                                  icon: Icons.arrow_back_rounded,
                                  onTap: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Копилка',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const Spacer(),
                                RoundIconButton(
                                  icon: Icons.edit_rounded,
                                  onTap: () => _editStart(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: kAmberGradient,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kAmber.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.savings_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 14),
                              DotMoney(
                                value: wallet.piggy,
                                size: 44,
                                color: cs.onSurface,
                              ),
                              Text(
                                'лежит на депозите',
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _PiggyAction(
                                  label: 'Положить',
                                  icon: Icons.south_rounded,
                                  filled: true,
                                  onTap: () => openTransferEditor(
                                    context,
                                    wallet,
                                    toPiggy: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PiggyAction(
                                  label: 'Снять',
                                  icon: Icons.north_rounded,
                                  filled: false,
                                  enabled: wallet.piggy > 0,
                                  onTap: () => openTransferEditor(
                                    context,
                                    wallet,
                                    toPiggy: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showStartHint)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Pressable(
                              onTap: () => _editStart(context),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: kAmber.withValues(
                                    alpha: dark ? 0.12 : 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: amberText(context),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'На депозите уже есть деньги? Впиши сумму, с которой начинаем.',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: const LinearGradient(
                                          colors: kAmberGradient,
                                        ),
                                      ),
                                      child: const Text(
                                        'Указать',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (transfers.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              'Здесь будет история: сколько положил и сколько снял.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        )
                      else
                        for (final entry in groups.entries) ...[
                          SliverToBoxAdapter(child: GroupTitle(entry.key)),
                          SliverToBoxAdapter(
                            child: DayCard(
                              items: entry.value,
                              piggyView: true,
                              onTap: (t) => openTxnEditor(context, wallet, t),
                              onDelete: (t) =>
                                  deleteWithUndo(context, wallet, t),
                              canDelete: (t) =>
                                  confirmDelete(context, wallet, t),
                            ),
                          ),
                        ],
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
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

class _PiggyAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;
  const _PiggyAction({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    final fg = filled ? Colors.white : amberText(context);
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: kFast,
        opacity: enabled ? 1 : 0.4,
        child: Pressable(
          onTap: onTap,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: filled
                  ? const LinearGradient(colors: kAmberGradient)
                  : null,
              color: filled
                  ? null
                  : (dark
                        ? const Color(0xFF1C1C1F).withValues(alpha: 0.62)
                        : Colors.white.withValues(alpha: 0.72)),
              border: filled
                  ? null
                  : Border.all(
                      color: kAmber.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
