import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kRed = Color(0xFFD71921);
const kTeal = Color(0xFFB8B8BE);
const kViolet = Color(0xFF6E6E74);
const kPeach = Color(0xFF8E8E93);
const kAmber = Color(0xFFA8A8AE);
const kAmberDeep = Color(0xFF5C5C62);
const kAmberGradient = [Color(0xFF55555B), Color(0xFF2C2C30)];

Color amberText(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFD8D8DC)
    : const Color(0xFF3A3A3F);

/// Doto has no Cyrillic or ₸ glyphs, so it is used for digits only.
const kDotoVariations = [
  FontVariation('wght', 800),
  FontVariation('ROND', 100),
];

Color mutedColor(Color c) => Color.lerp(c, const Color(0xFF8E8E93), 0.35)!;

const kFast = Duration(milliseconds: 220);

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

SystemUiOverlayStyle overlayFor(BuildContext context) => isDark(context)
    ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
    : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

const kSlate = Color(0xFF9A9AA0);

const kSlateGradient = kAmberGradient;

const kDanger = kRed;

Color slateText(BuildContext c) => amberText(c);

Color accentOf(BuildContext c) => Theme.of(c).colorScheme.secondary;

/// Text on glass and cards: at least 4.5:1 on the dark palette.
Color mutedText(BuildContext c) {
  final cs = Theme.of(c).colorScheme;
  return cs.onSurface.withValues(alpha: isDark(c) ? 0.62 : 0.66);
}
