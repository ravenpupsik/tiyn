import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';

class SolidCard extends StatelessWidget {
  final List<Widget> children;
  const SolidCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final divider = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.06);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF1C1C1F).withValues(alpha: 0.62)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 72, color: divider),
            children[i],
          ],
        ],
      ),
    );
  }
}
