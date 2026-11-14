import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

class AnimatedMoney extends StatelessWidget {
  final int value;
  final TextStyle style;
  const AnimatedMoney({super.key, required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(formatMoney(v.round()), style: style),
      ),
    );
  }
}

class BigMoney extends StatelessWidget {
  final int value;
  final double size;
  final Color color;
  final Alignment alignment;
  const BigMoney({
    super.key,
    required this.value,
    required this.size,
    required this.color,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          formatMoney(v.round()),
          style: literata(size, color: color, height: 1.2),
        ),
      ),
    );
  }
}
