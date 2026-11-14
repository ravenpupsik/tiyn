import 'package:flutter/material.dart';

import 'package:money_app/screens/home/glass_add_button.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/frosted_glass.dart';

class HomeTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  const HomeTabBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  static const _tabs = [
    (Icons.home_rounded, 'Главная'),
    (Icons.pie_chart_rounded, 'Статистика'),
    (Icons.event_note_rounded, 'Планы'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: FrostedGlass(
                radius: const BorderRadius.all(Radius.circular(31)),
                padding: const EdgeInsets.all(5),
                blur: 20,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _TabItem(
                            icon: _tabs[i].$1,
                            label: _tabs[i].$2,
                            selected: i == index,
                            onTap: () => onSelect(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GlassAddButton(onTap: onAdd),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.45);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: kFast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? cs.onSurface.withValues(alpha: isDark(context) ? 0.12 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: fg),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedOpacity(
              duration: kFast,
              opacity: selected ? 1 : 0,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: accentOf(context),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
