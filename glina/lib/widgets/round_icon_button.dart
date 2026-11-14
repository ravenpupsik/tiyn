import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/pressable.dart';

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: label != null,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: g.surf),
          child: Icon(icon, color: g.ink, size: 22),
        ),
      ),
    );
  }
}
