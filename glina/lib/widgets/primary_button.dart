import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: g.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label, style: golos(16, 700, color: g.onAccent)),
        ),
      ),
    );
  }
}
