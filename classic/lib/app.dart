import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:money_app/screens/home/home_page.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/tokens.dart';

class TiynApp extends StatelessWidget {
  const TiynApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b, AccentId accent) {
      final dark = b == Brightness.dark;
      final scheme =
          ColorScheme.fromSeed(
            seedColor: kPeach,
            brightness: b,
            dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          ).copyWith(
            primary: dark ? const Color(0xFFF2F2F2) : const Color(0xFF111111),
            onPrimary: dark ? const Color(0xFF111111) : const Color(0xFFF2F2F2),
            secondary: accent.forBrightness(b),
            tertiary: kViolet,
            surface: dark ? const Color(0xFF050506) : const Color(0xFFE9E9EC),
          );
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        splashFactory: InkSparkle.splashFactory,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return ListenableBuilder(
      listenable: appTheme,
      builder: (context, _) => MaterialApp(
        title: 'Tiyn',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light, appTheme.accent),
        darkTheme: theme(Brightness.dark, appTheme.accent),
        themeMode: appTheme.mode,
        // Russian locale is required by the date picker dialogs.
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const IntroGate(child: HomePage()),
      ),
    );
  }
}
