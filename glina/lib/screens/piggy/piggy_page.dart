import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/editor/editor_actions.dart';
import 'package:money_app/screens/piggy/piggy_start_sheet.dart';
import 'package:money_app/theme/cat_icons.dart';
import 'package:money_app/theme/glina_theme.dart';
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
    final g = context.g;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(context),
      child: Scaffold(
        backgroundColor: g.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: Backdrop()),
            Positioned.fill(
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
                                  label: 'Назад',
                                  onTap: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Копилка',
                                  style: golos(22, 700, color: g.ink),
                                ),
                                const Spacer(),
                                RoundIconButton(
                                  icon: Icons.edit_outlined,
                                  label: 'Изменить сумму',
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
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Glina.tint(g.accent, g.surf),
                                ),
                                child: CatIcon(
                                  'piggy',
                                  color: g.accent,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 14),
                              BigMoney(
                                value: wallet.piggy,
                                size: 44,
                                color: g.ink,
                                alignment: Alignment.center,
                              ),
                              Text(
                                'лежит на депозите',
                                style: golos(14, 500, color: g.ink2),
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
                                  color: Glina.tint(g.accent, g.surf),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: g.accentText,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'На депозите уже есть деньги? Впиши сумму, с которой начинаем.',
                                        style: golos(13, 500, color: g.ink),
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
                                        color: g.accent,
                                      ),
                                      child: Text(
                                        'Указать',
                                        style: golos(
                                          13,
                                          700,
                                          color: g.onAccent,
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
                              style: golos(
                                14,
                                500,
                                color: g.ink3,
                                height: 1.35,
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
    final g = context.g;
    final fg = filled ? g.onAccent : g.ink;
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: kFast,
        opacity: enabled ? 1 : 0.5,
        child: Pressable(
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: filled ? g.accent : g.surf,
              border: filled ? null : Border.all(color: g.line, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 18),
                const SizedBox(width: 8),
                Text(label, style: golos(16, 700, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
