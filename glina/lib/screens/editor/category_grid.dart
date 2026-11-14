import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/theme/cat_icons.dart';
import 'package:money_app/theme/tokens.dart';

class CatGrid extends StatelessWidget {
  final List<Category> cats;
  final String selected;
  final bool centered;
  final ValueChanged<Category> onTap;
  const CatGrid({
    super.key,
    required this.cats,
    required this.selected,
    required this.centered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <List<Category>>[
      for (var i = 0; i < cats.length; i += 4)
        cats.sublist(i, i + 4 > cats.length ? cats.length : i + 4),
    ];
    return Column(
      children: [
        for (final row in rows)
          SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: centered
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                for (var i = 0; i < 4; i++)
                  if (i < row.length)
                    _CatCell(
                      cat: row[i],
                      selected: row[i].name == selected,
                      onTap: () => onTap(row[i]),
                    )
                  else if (!centered)
                    const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}

class _CatCell extends StatelessWidget {
  final Category cat;
  final bool selected;
  final VoidCallback onTap;
  const _CatCell({
    required this.cat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final color = cat.forDark(g.dark);
    final cell = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Semantics(
        button: true,
        selected: selected,
        label: cat.name,
        excludeSemantics: true,
        child: Column(
          children: [
            const SizedBox(height: 2),
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected ? Border.all(color: color, width: 2) : null,
              ),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Glina.tint(color, g.surf),
                  shape: BoxShape.circle,
                ),
                child: CatIcon(cat.icon, color: color, size: 22),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cat.name,
              maxLines: 1,
              style: golos(
                11,
                selected ? 700 : 500,
                color: selected ? g.ink : g.ink2,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
    return SizedBox(width: 80, child: cell);
  }
}
