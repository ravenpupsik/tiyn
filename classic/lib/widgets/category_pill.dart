import 'package:flutter/material.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/pressable.dart';

class CategoryPill extends StatelessWidget {
  final Category cat;
  final bool selected;
  final VoidCallback onTap;
  const CategoryPill({
    super.key,
    required this.cat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kFast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? cs.onSurface.withValues(alpha: dark ? 0.16 : 0.10)
              : cs.onSurface.withValues(alpha: dark ? 0.07 : 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.onSurface.withValues(alpha: 0.7)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cat.icon,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              cat.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
