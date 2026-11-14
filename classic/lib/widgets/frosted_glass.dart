import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';

class FrostedGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius radius;
  final EdgeInsets padding;
  final double blur;

  final double fill;
  const FrostedGlass({
    super.key,
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(28)),
    this.padding = const EdgeInsets.all(20),
    this.blur = 14,
    this.fill = 0,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: fill > 0
                  ? (dark
                        ? [
                            const Color(0xFF2C2C30).withValues(alpha: fill),
                            const Color(0xFF141416).withValues(alpha: fill),
                          ]
                        : [
                            Colors.white.withValues(alpha: fill),
                            const Color(0xFFF1F1F3).withValues(alpha: fill),
                          ])
                  : dark
                  ? [
                      const Color(0xFF2A2A2E).withValues(alpha: 0.62),
                      const Color(0xFF141416).withValues(alpha: 0.5),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.45),
                    ],
            ),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.07),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
