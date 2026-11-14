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
        child: Text(
          formatMoney(v.round()),
          style: style.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Big amount in the Doto dot font. Digits use Doto; the ₸ sign uses a regular
/// font (Doto has no glyph for it).
class DotMoney extends StatelessWidget {
  final int value;
  final double size;
  final Color color;
  const DotMoney({
    super.key,
    required this.value,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) {
        final text = formatMoney(v.round());
        final digits = text.substring(0, text.length - 2);
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: digits,
                  style: TextStyle(
                    fontFamily: 'Doto',
                    fontVariations: kDotoVariations,
                    fontSize: size,
                    height: 1.1,
                    wordSpacing: -size * 0.28,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' ₸',
                  style: TextStyle(
                    fontSize: size * 0.6,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
