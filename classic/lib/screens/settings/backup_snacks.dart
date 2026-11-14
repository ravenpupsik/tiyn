import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/theme/app_theme.dart';

void showRestoredSnack(BuildContext context, Wallet wallet) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Данные восстановлены'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () async {
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
                  content: Text(
                    ok
                        ? 'Прежние данные возвращены'
                        : 'Не удалось вернуть данные',
                  ),
                ),
              );
          },
        ),
      ),
    );
}
