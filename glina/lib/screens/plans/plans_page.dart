import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/plans/plan_actions.dart';
import 'package:money_app/screens/plans/plan_tile.dart';
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/widgets/group_title.dart';
import 'package:money_app/widgets/money.dart';
import 'package:money_app/widgets/pressable.dart';
import 'package:money_app/widgets/round_icon_button.dart';
import 'package:money_app/widgets/solid_card.dart';
import 'package:money_app/widgets/surf_panel.dart';

class PlansPage extends StatelessWidget {
  final Wallet wallet;

  /// true: the screen lives in a tab (no Back button, no own background).
  final bool inTab;
  const PlansPage({super.key, required this.wallet, this.inTab = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    final muted = context.g.ink2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (!inTab) const Positioned.fill(child: Backdrop()),
            Positioned.fill(
              child: ListenableBuilder(
                listenable: wallet,
                builder: (context, _) {
                  final plans = wallet.plans;
                  final free = wallet.free;
                  final bad = free < 0;
                  return CustomScrollView(
                    slivers: [
                      SliverSafeArea(
                        bottom: false,
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Row(
                              children: [
                                if (!inTab) ...[
                                  RoundIconButton(
                                    icon: Icons.arrow_back_rounded,
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  const SizedBox(width: 8),
                                ] else
                                  const SizedBox(width: 8),
                                Text(
                                  'Планы',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
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
                                  color: Glina.tint(
                                    context.g.accent,
                                    context.g.surf,
                                  ),
                                ),
                                child: Icon(
                                  Icons.event_note_outlined,
                                  color: context.g.accentText,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 14),
                              BigMoney(
                                value: free,
                                size: 44,
                                color: bad
                                    ? context.g.accentText
                                    : cs.onSurface,
                              ),
                              Text(
                                bad
                                    ? 'не хватает на все планы'
                                    : 'свободно после всех планов',
                                style: TextStyle(color: muted),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'На руках ${formatMoney(wallet.onHand)}, запланировано ${formatMoney(wallet.planned)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.g.ink3,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                          child: Pressable(
                            onTap: () => openPlanEditor(context, wallet),
                            child: SurfPanel(
                              radius: BorderRadius.circular(20),
                              padding: EdgeInsets.zero,
                              child: SizedBox(
                                height: 54,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: context.g.accentText,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Добавить план',
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (plans.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              'Запиши траты, которые ещё впереди: зубной, подарок, билеты. Деньги остаются на счёте, просто видно, сколько из них уже занято.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.g.ink3),
                            ),
                          ),
                        )
                      else ...[
                        const SliverToBoxAdapter(child: GroupTitle('Впереди')),
                        SliverToBoxAdapter(
                          child: SolidCard(
                            children: [
                              for (final p in plans)
                                PlanTile(
                                  plan: p,
                                  onTap: () =>
                                      openPlanEditor(context, wallet, p),
                                  onPay: () => payPlan(context, wallet, p),
                                  onDelete: () =>
                                      deletePlanWithUndo(context, wallet, p),
                                ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                            child: Text(
                              'Нажми, чтобы изменить. Свайп влево удаляет.',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(
                                  alpha: dark ? 0.4 : 0.45,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: SizedBox(height: inTab ? 130 : 40),
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
