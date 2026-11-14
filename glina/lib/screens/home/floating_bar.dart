import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/surf_panel.dart';

class FloatingBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  const FloatingBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  static const _tabs = [
    (Icons.home_outlined, 'Главная'),
    (Icons.bar_chart_rounded, 'Статистика'),
    (Icons.calendar_today_outlined, 'Планы'),
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: g.surf,
            borderRadius: BorderRadius.circular(32),
            boxShadow: glinaShadow(g),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                SizedBox(
                  width: 78,
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
        const SizedBox(width: 12),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Добавить',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              onAdd();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: g.accent,
                shape: BoxShape.circle,
                boxShadow: glinaShadow(g),
              ),
              child: Icon(Icons.add_rounded, size: 24, color: g.onAccent),
            ),
          ),
        ),
      ],
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
    final g = context.g;
    final fg = selected ? g.accentText : g.ink3;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: golos(10, selected ? 700 : 600, color: fg, height: 1.2),
          ),
        ],
      ),
    );
  }
}
