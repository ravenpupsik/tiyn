import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'package:money_app/app.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/services/tiyn_home_widget.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/widgets/backdrop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Reminder.platformEnabled = true;
  TiynHomeWidget.platformEnabled = true;
  // Only what the first frame depends on runs before runApp: the theme (no
  // flash of the wrong colors) and whether the app was opened from a
  // notification or the widget (skips the intro).
  await Future.wait([
    _guard(appTheme.load()),
    _guard(
      Reminder.detectLaunch(),
      onError: () => Reminder.platformEnabled = false,
    ),
    _guard(
      _listenToWidget(),
      onError: () => TiynHomeWidget.platformEnabled = false,
    ),
  ]);
  introEnabled = !Reminder.launchedFromTap;
  runApp(const TiynApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => _finishStartup());
}

/// The rest of the startup, after the first frame is on screen.
void _finishStartup() {
  unawaited(loadChromeProgram());
  unawaited(
    _guard(Reminder.init(), onError: () => Reminder.platformEnabled = false),
  );
}

Future<void> _guard(Future<void> f, {void Function()? onError}) async {
  try {
    await f;
  } catch (_) {
    onError?.call();
  }
}

Future<void> _listenToWidget() async {
  final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  // Opened from a notification or the widget "+": go straight to the editor
  // and skip the intro.
  if (uri?.host == 'add') Reminder.launchedFromTap = true;
  HomeWidget.widgetClicked.listen((u) {
    if (u?.host == 'add') Reminder.openAdd.value++;
  });
}
