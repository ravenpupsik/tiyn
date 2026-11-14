import 'dart:async';

import 'package:flutter/material.dart';

import 'package:money_app/data/period.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

class PeriodChips extends StatelessWidget {
  final PeriodKind selected;
  final ValueChanged<PeriodKind> onSelect;
  const PeriodChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static const _items = [
    (PeriodKind.week, '7 дней'),
    (PeriodKind.month, 'Месяц'),
    (PeriodKind.custom, 'Период'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _Chip(
            label: _items[i].$2,
            active: _items[i].$1 == selected,
            onTap: () => onSelect(_items[i].$1),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final Color fill, text;
    Color? border;
    if (active) {
      fill = g.accent;
      text = g.onAccent;
    } else {
      fill = g.surf;
      border = g.line;
      text = g.ink2;
    }
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(17),
            border: border == null ? null : Border.all(color: border),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: DefaultTextStyle.of(context).style.merge(
              TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class PeriodPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PeriodPill({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final ink = g.ink;
    return Semantics(
      button: true,
      label: 'Период: $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: g.surf,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: g.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: ink.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ink.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: ink.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns null if closed without picking. Future dates are not selectable; the
/// earliest date is the first entry.
Future<StatPeriod?> pickStatPeriod(
  BuildContext context, {
  required StatPeriod initial,
  required DateTime firstRecord,
  DateTime? now,
}) async {
  final today = dateOnly(now ?? DateTime.now());
  var first = dateOnly(firstRecord);
  if (first.isAfter(today)) first = today;
  // The previous period may start before the first entry (or end later): clamp
  // it, otherwise the picker fails an assert.
  final start = initial.start.isBefore(first) ? first : initial.start;
  var end = initial.end.isAfter(today) ? today : initial.end;
  if (end.isBefore(start)) end = start;

  final base = Theme.of(context);
  final g = Glina.of(context);
  final neutral = g.accent;
  final onNeutral = g.onAccent;
  final surface = g.surf;
  final red = g.accent;

  final range = await showDateRangePicker(
    context: context,
    firstDate: first,
    lastDate: today,
    currentDate: today,
    initialDateRange: DateTimeRange(start: start, end: end),
    saveText: 'Готово',
    builder: (context, child) => Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: neutral,
          onPrimary: onNeutral,
          surface: surface,
          onSurface: g.ink,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: surface,
          rangePickerBackgroundColor: surface,
          rangeSelectionBackgroundColor: neutral.withValues(alpha: 0.18),
          todayForegroundColor: WidgetStatePropertyAll(red),
          todayBorder: BorderSide(color: red),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: g.accentText),
        ),
      ),
      child: child!,
    ),
  );
  if (range == null) return null;
  return StatPeriod.custom(range.start, range.end);
}

String periodLabel(StatPeriod p, {DateTime? now}) =>
    formatRangeLabel(p.start, p.end, now: now);
