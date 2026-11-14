import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/period.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/editor/editor_actions.dart';
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/widgets/cat_bubble.dart';
import 'package:money_app/widgets/day_card.dart';
import 'package:money_app/widgets/group_title.dart';
import 'package:money_app/widgets/round_icon_button.dart';

class CategoryTxnsPage extends StatelessWidget {
  final Wallet wallet;
  final Category category;
  final StatPeriod period;

  final String title;
  const CategoryTxnsPage({
    super.key,
    required this.wallet,
    required this.category,
    required this.period,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: Backdrop()),
            Positioned.fill(
              child: ListenableBuilder(
                listenable: wallet,
                builder: (context, _) {
                  final list = wallet.items
                      .where(
                        (t) =>
                            isSpending(t) &&
                            period.contains(t.date) &&
                            findCategory(t.category, false).name ==
                                category.name,
                      )
                      .toList();
                  final total = list.fold(0, (s, t) => s + t.amount);
                  final groups = <DateTime, List<Txn>>{};
                  for (final t in list) {
                    groups.putIfAbsent(dateOnly(t.date), () => []).add(t);
                  }
                  return CustomScrollView(
                    slivers: [
                      SliverSafeArea(
                        bottom: false,
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(
                              children: [
                                RoundIconButton(
                                  icon: Icons.arrow_back_rounded,
                                  onTap: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 12),
                                CatBubble(category, diameter: 38),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '$title · ${formatMoney(total)}',
                                        style: TextStyle(color: context.g.ink2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (list.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'Здесь больше ничего нет',
                              style: TextStyle(color: context.g.ink3),
                            ),
                          ),
                        )
                      else
                        for (final entry in groups.entries) ...[
                          SliverToBoxAdapter(
                            child: GroupTitle(
                              formatDayHeader(entry.key),
                              sum: daySpending(entry.value),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: DayCard(
                              items: entry.value,
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
