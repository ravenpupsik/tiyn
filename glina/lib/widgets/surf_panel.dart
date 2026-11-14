import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';

class SurfPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius radius;
  final EdgeInsets padding;
  final bool shadow;
  final Color? color;
  const SurfPanel({
    super.key,
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(28)),
    this.padding = const EdgeInsets.all(20),
    this.shadow = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? g.surf,
        borderRadius: radius,
        boxShadow: shadow ? glinaShadow(g) : null,
      ),
      child: child,
    );
  }
}

List<BoxShadow> glinaShadow(Glina g) => [
  BoxShadow(
    color: (g.dark ? Colors.black : const Color(0xFF6A4A32)).withValues(
      alpha: g.dark ? 0.35 : 0.12,
    ),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];
