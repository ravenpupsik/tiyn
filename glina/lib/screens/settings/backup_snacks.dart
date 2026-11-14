import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/theme/app_theme.dart';

void showBackupSnack(
  BuildContext context,
  String text, {
  required double bottom,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: SizedBox(
          height: 48,
          child: Align(alignment: Alignment.centerLeft, child: Text(text)),
        ),
        duration: duration,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
        padding: EdgeInsets.fromLTRB(16, 0, actionLabel == null ? 16 : 4, 0),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

const _kBarHeight = 64.0;

double homeSnackBottom(BuildContext context) => 12 + _kBarHeight + 12;

void showRestoredSnack(BuildContext context, Wallet wallet) {
  final messenger = ScaffoldMessenger.of(context);
  final bottom = homeSnackBottom(context);
  showBackupSnack(
    context,
    'Данные восстановлены',
    bottom: bottom,
    actionLabel: 'Отменить',
    duration: const Duration(seconds: 6),
    onAction: () async {
      var ok = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        ok = await Backup.undo(prefs);
        await appTheme.load();
        await Reminder.reloadSettings();
        await wallet.load();
      } catch (_) {
        ok = false;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ok
                      ? 'Прежние данные возвращены'
                      : 'Не удалось вернуть данные',
                ),
              ),
            ),
            margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        );
    },
  );
}
