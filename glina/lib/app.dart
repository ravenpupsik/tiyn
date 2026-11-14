import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:money_app/screens/home/home_page.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/glina_theme.dart';

class TiynApp extends StatelessWidget {
  const TiynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appTheme,
      builder: (context, _) => _app(),
    );
  }

  Widget _app() {
    return MaterialApp(
      title: 'Tiyn',
      debugShowCheckedModeBanner: false,
      theme: glinaTheme(Brightness.light, appTheme.accent),
      darkTheme: glinaTheme(Brightness.dark, appTheme.accent),
      themeMode: appTheme.mode,
      // Russian locale is required by the date picker dialogs.
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // The layout assumes a normal font size: clamp strong system font
        // scaling.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child!,
        );
      },
      home: const IntroGate(child: HomePage()),
    );
  }
}
