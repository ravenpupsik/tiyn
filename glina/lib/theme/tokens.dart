import 'package:flutter/material.dart';

const kGolos = 'GolosText';
const kLiterata = 'Literata';
const kNunito = 'Nunito';

/// Tabular figures: amounts align by digit.
const kTabular = [FontFeature.tabularFigures()];

TextStyle golos(
  double size,
  double w, {
  Color? color,
  double? height,
  double? letterSpacing,
}) => TextStyle(
  fontFamily: kGolos,
  fontSize: size,
  fontVariations: [FontVariation('wght', w)],
  fontFeatures: kTabular,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

/// Literata: only big amounts. Optical size (opsz) is set close to the font
/// size, within the font axes (7…72).
TextStyle literata(
  double size, {
  double w = 650,
  Color? color,
  double? height,
}) => TextStyle(
  fontFamily: kLiterata,
  fontSize: size,
  fontVariations: [
    FontVariation('opsz', size.clamp(7, 72).toDouble()),
    FontVariation('wght', w),
  ],
  fontFeatures: kTabular,
  color: color,
  height: height,
);

TextStyle nunito(double size, double w, {Color? color, double? height}) =>
    TextStyle(
      fontFamily: kNunito,
      fontSize: size,
      fontVariations: [FontVariation('wght', w)],
      color: color,
      height: height,
    );

enum AccentId {
  clay('clay', 'Глина'),
  red('red', 'Красный'),
  blue('blue', 'Синий');

  final String id;
  final String label;
  const AccentId(this.id, this.label);

  static AccentId parse(Object? raw) {
    for (final a in values) {
      if (a.id == raw) return a;
    }
    return clay;
  }

  /// Colors: accent and accentText for the light theme, accent (also
  /// accentText) for the dark one. Contrast is at least 4.5 everywhere.
  (Color, Color, Color) get colors => switch (this) {
    clay => (Color(0xFFB84728), Color(0xFF9E3A1E), Color(0xFFE39270)),
    red => (Color(0xFFD71921), Color(0xFFB3151C), Color(0xFFF28C85)),
    blue => (Color(0xFF2F5DA8), Color(0xFF2A5396), Color(0xFF8FB0E6)),
  };
}

/// A theme extension: [Glina.of] reads it from `Theme`, so changing the theme
/// or accent repaints all screens.
class Glina extends ThemeExtension<Glina> {
  final Brightness brightness;
  final AccentId accentId;
  final Color bg, surf, surf2, line, ink, ink2, ink3;
  final Color accent, accentText, onAccent, pos;

  const Glina._({
    required this.brightness,
    this.accentId = AccentId.clay,
    required this.bg,
    required this.surf,
    required this.surf2,
    required this.line,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.pos,
  });

  bool get dark => brightness == Brightness.dark;

  static const light = Glina._(
    brightness: Brightness.light,
    bg: Color(0xFFF3EBE3),
    surf: Color(0xFFFFF7F0),
    surf2: Color(0xFFE8DCD0),
    line: Color(0xFFE0D4C8),
    ink: Color(0xFF2A211C),
    ink2: Color(0xFF6A5C53),
    ink3: Color(0xFF8D7E74),
    accent: Color(0xFFB84728),
    accentText: Color(0xFF9E3A1E),
    onAccent: Color(0xFFFFF7F0),
    pos: Color(0xFF1F6B43),
  );

  static const darkTheme = Glina._(
    brightness: Brightness.dark,
    bg: Color(0xFF1A1613),
    surf: Color(0xFF2A2320),
    surf2: Color(0xFF352C27),
    line: Color(0xFF3F352F),
    ink: Color(0xFFF3EBE3),
    ink2: Color(0xFFB5A79C),
    ink3: Color(0xFF8C7E74),
    accent: Color(0xFFE39270),
    accentText: Color(0xFFE39270),
    onAccent: Color(0xFF1A1613),
    pos: Color(0xFF7DCCA0),
  );

  static final Map<(Brightness, AccentId), Glina> _cache = {};

  /// Only accent and accentText change; bg, ink, onAccent, pos and category
  /// colors stay the same.
  static Glina palette(Brightness b, [AccentId a = AccentId.clay]) {
    return _cache.putIfAbsent((b, a), () {
      final base = b == Brightness.dark ? darkTheme : light;
      final (accent, accentText, darkAccent) = a.colors;
      return base._with(
        a,
        b == Brightness.dark ? darkAccent : accent,
        b == Brightness.dark ? darkAccent : accentText,
      );
    });
  }

  Glina _with(AccentId id, Color accent, Color accentText) => Glina._(
    brightness: brightness,
    accentId: id,
    bg: bg,
    surf: surf,
    surf2: surf2,
    line: line,
    ink: ink,
    ink2: ink2,
    ink3: ink3,
    accent: accent,
    accentText: accentText,
    onAccent: onAccent,
    pos: pos,
  );

  static Glina of(BuildContext c) {
    final t = Theme.of(c);
    return t.extension<Glina>() ?? byBrightness(t.brightness);
  }

  static Glina byBrightness(Brightness b, [AccentId a = AccentId.clay]) =>
      palette(b, a);

  static Color tint(Color color, Color surface) =>
      Color.alphaBlend(color.withValues(alpha: 0.15), surface);

  Color get field => dark ? surf2 : surf2.withValues(alpha: 0.55);

  ColorScheme get scheme => ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: onAccent,
    secondary: accent,
    onSecondary: onAccent,
    error: accent,
    onError: onAccent,
    surface: surf,
    onSurface: ink,
    surfaceContainerHighest: surf2,
    outline: line,
    outlineVariant: line,
  );

  @override
  Glina copyWith({
    Brightness? brightness,
    AccentId? accentId,
    Color? bg,
    Color? surf,
    Color? surf2,
    Color? line,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? accent,
    Color? accentText,
    Color? onAccent,
    Color? pos,
  }) => Glina._(
    brightness: brightness ?? this.brightness,
    accentId: accentId ?? this.accentId,
    bg: bg ?? this.bg,
    surf: surf ?? this.surf,
    surf2: surf2 ?? this.surf2,
    line: line ?? this.line,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    accent: accent ?? this.accent,
    accentText: accentText ?? this.accentText,
    onAccent: onAccent ?? this.onAccent,
    pos: pos ?? this.pos,
  );

  @override
  Glina lerp(ThemeExtension<Glina>? other, double t) {
    if (other is! Glina) return this;
    if (t <= 0) return this;
    if (t >= 1) return other;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Glina._(
      brightness: t < 0.5 ? brightness : other.brightness,
      accentId: t < 0.5 ? accentId : other.accentId,
      bg: c(bg, other.bg),
      surf: c(surf, other.surf),
      surf2: c(surf2, other.surf2),
      line: c(line, other.line),
      ink: c(ink, other.ink),
      ink2: c(ink2, other.ink2),
      ink3: c(ink3, other.ink3),
      accent: c(accent, other.accent),
      accentText: c(accentText, other.accentText),
      onAccent: c(onAccent, other.onAccent),
      pos: c(pos, other.pos),
    );
  }
}

extension GlinaContext on BuildContext {
  Glina get g => Glina.of(this);
}
