import 'dart:async';

import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/backdrop.dart';

Future<T?> showGlassSheet<T>(BuildContext context, Widget child) {
  backdropPaused.value = true; // background stays still while the sheet is open
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: isDark(context) ? 0.35 : 0.12),
    builder: (_) => child,
  ).whenComplete(() => backdropPaused.value = false);
}
