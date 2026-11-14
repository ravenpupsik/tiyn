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

import 'package:money_app/screens/settings/settings_widgets.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/tokens.dart';

class ReminderTimeSheet extends StatelessWidget {
  const ReminderTimeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = Reminder.hour, m = Reminder.minute;
    return SettingsSheet(
      children: [
        const SheetTitle('Время напоминания'),
        const SizedBox(height: 6),
        const SheetNote(
          'Каждый вечер спрошу, записал ли ты траты.\nЕсли за день уже есть запись, промолчу.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Theme.of(context).brightness,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  fontSize: 22,
                  color: cs.onSurface,
                ),
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
      builder: (context, _) => SettingsSheet(
        children: [
          const SheetTitle('Тема'),
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
        ],
      ),
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
    final cs = Theme.of(context).colorScheme;
    final accent = accentOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 6),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accent : mutedText(context),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
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
      builder: (context, _) => SettingsSheet(
        children: [
          const SheetTitle('Акцент'),
          const SizedBox(height: 6),
          const SheetNote('Цвета категорий и доходов не меняются'),
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
      ),
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
    final cs = Theme.of(context).colorScheme;
    final fill = accent.forBrightness(Theme.of(context).brightness);
    return Semantics(
      button: true,
      selected: selected,
      label: accent.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 92,
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
                    color: selected ? cs.onSurface : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 22,
                          color: isDark(context)
                              ? const Color(0xFF111111)
                              : Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                accent.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
