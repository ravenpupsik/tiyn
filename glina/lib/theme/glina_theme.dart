import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/tokens.dart';

const kAccentLight = Color(0xFFB84728);

const kFast = Duration(milliseconds: 220);

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

/// Light-theme accent of the chosen color, for places without a context
/// (notification color).
Color get currentAccentLight =>
    Glina.palette(Brightness.light, appTheme.accent).accent;

ThemeData glinaTheme(Brightness b, [AccentId accent = AccentId.clay]) {
  final g = Glina.palette(b, accent);
  final base = ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: g.scheme,
    fontFamily: kGolos,
    scaffoldBackgroundColor: g.bg,
    canvasColor: g.surf,
    dividerColor: g.line,
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
    extensions: [g],
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(fontFamily: kGolos, bodyColor: g.ink, displayColor: g.ink)
        .copyWith(
          bodyLarge: golos(16, 500, color: g.ink),
          bodyMedium: golos(14, 500, color: g.ink),
          bodySmall: golos(12, 500, color: g.ink2),
          labelLarge: golos(14, 600, color: g.ink),
          titleMedium: golos(16, 600, color: g.ink),
          titleLarge: golos(20, 700, color: g.ink),
        ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: g.ink,
      contentTextStyle: golos(14, 500, color: g.bg),
      // The snackbar is inverted, so use the accent text of the opposite theme
      // with the same accent (clay: #9E3A1E on the light snackbar of the dark
      // theme, #E39270 on the dark one of the light theme).
      actionTextColor: Glina.palette(
        b == Brightness.dark ? Brightness.light : Brightness.dark,
        accent,
      ).accentText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: g.accent,
      selectionColor: g.accent.withValues(alpha: 0.25),
      selectionHandleColor: g.accent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(g.onAccent),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? g.accent : g.surf2,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    // Date picker: "today" uses the accent; the selected day and buttons are
    // neutral.
    datePickerTheme: DatePickerThemeData(
      backgroundColor: g.surf,
      rangePickerBackgroundColor: g.surf,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: g.surf,
      headerForegroundColor: g.ink,
      rangeSelectionBackgroundColor: g.ink.withValues(alpha: 0.14),
      todayForegroundColor: WidgetStatePropertyAll(g.accent),
      todayBorder: BorderSide(color: g.accent),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? g.bg : g.ink,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? g.ink : null,
      ),
      yearForegroundColor: WidgetStatePropertyAll(g.ink),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: g.ink),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: g.ink),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: g.ink),
    ),
  );
}

SystemUiOverlayStyle overlayFor(BuildContext context) => isDark(context)
    ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
    : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);
