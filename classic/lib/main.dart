import 'dart:async';
import 'dart:ui' show FragmentProgram;

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
  try {
    chromeProgram = await FragmentProgram.fromAsset('shaders/chrome.frag');
  } catch (_) {
    chromeProgram = null;
  }
  try {
    await appTheme.load();
  } catch (_) {}
  Reminder.platformEnabled = true;
  TiynHomeWidget.platformEnabled = true;
  try {
    await Reminder.init();
  } catch (_) {
    Reminder.platformEnabled = false;
  }
  try {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri?.host == 'add') Reminder.launchedFromTap = true;
    HomeWidget.widgetClicked.listen((u) {
      if (u?.host == 'add') Reminder.openAdd.value++;
    });
  } catch (_) {
    TiynHomeWidget.platformEnabled = false;
  }
  // Opened from a notification or the widget "+": go straight to the editor and
  // skip the intro.
  introEnabled = !Reminder.launchedFromTap;
  runApp(const TiynApp());
}
