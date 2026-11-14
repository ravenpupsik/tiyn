import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/pressable.dart';

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.onSurface.withValues(alpha: isDark(context) ? 0.10 : 0.06),
        ),
        child: Icon(icon, color: cs.onSurface.withValues(alpha: 0.8)),
      ),
    );
  }
}
