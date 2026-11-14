import 'dart:async';

import 'package:flutter/cupertino.dart'
    show
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoTheme,
        CupertinoThemeData,
        CupertinoTextThemeData;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/screens/settings/settings_sheet.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/tokens.dart';

class ReminderTimeSheet extends StatelessWidget {
  const ReminderTimeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final h = Reminder.hour, m = Reminder.minute;
    return SettingsSheet(
      children: [
        SizedBox(
          height: 28,
          child: Text('Время напоминания', style: golos(20, 700, color: g.ink)),
        ),
        const SizedBox(height: 4),
        Text(
          'Каждый вечер спрошу, записал ли ты траты.\nЕсли за день уже есть запись, промолчу.',
          style: golos(13, 500, color: g.ink2, height: 1.35),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Theme.of(context).brightness,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: golos(22, 500, color: g.ink),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              minuteInterval: 5,
              initialDateTime: DateTime(2000, 1, 1, h, m - m % 5),
              onDateTimeChanged: (d) => Reminder.setTime(d.hour, d.minute),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class ThemeSheet extends StatelessWidget {
  final VoidCallback? onChanged;
  const ThemeSheet({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appTheme,
      builder: (context, _) {
        final g = context.g;
        return SettingsSheet(
          children: [
            SizedBox(
              height: 28,
              child: Text('Тема', style: golos(20, 700, color: g.ink)),
            ),
            const SizedBox(height: 8),
            for (final m in ThemeMode.values)
              _RadioRow(
                label: themeModeLabel(m),
                selected: appTheme.mode == m,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await appTheme.setMode(m);
                  onChanged?.call();
                  await Future<void>.delayed(const Duration(milliseconds: 180));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _RadioRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? g.accent : g.ink3,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: g.accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: golos(16, 600, color: g.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccentSheet extends StatelessWidget {
  final VoidCallback? onChanged;
  const AccentSheet({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appTheme,
      builder: (context, _) {
        final g = context.g;
        return SettingsSheet(
          children: [
            SizedBox(
              height: 28,
              child: Text('Акцент', style: golos(20, 700, color: g.ink)),
            ),
            const SizedBox(height: 4),
            Text(
              'Цвета категорий и доходов не меняются',
              style: golos(13, 500, color: g.ink2),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final a in AccentId.values)
                  _AccentDot(
                    accent: a,
                    selected: appTheme.accent == a,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await appTheme.setAccent(a);
                      onChanged?.call();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _AccentDot extends StatelessWidget {
  final AccentId accent;
  final bool selected;
  final VoidCallback onTap;
  const _AccentDot({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final p = Glina.palette(g.brightness, accent);
    return Semantics(
      button: true,
      selected: selected,
      label: accent.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 88,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? g.ink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.accent,
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, size: 22, color: p.onAccent)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                accent.label,
                style: golos(13, selected ? 700 : 500, color: g.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
