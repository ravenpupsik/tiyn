import 'package:flutter/material.dart';

import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/settings/settings_widgets.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

String formatBackupStamp(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final l = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${formatShortDate(l, now: n)}, ${two(l.hour)}:${two(l.minute)}';
}

class ConfirmRestoreSheet extends StatelessWidget {
  final String fileName;
  final BackupFile file;
  const ConfirmRestoreSheet({
    super.key,
    required this.fileName,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = mutedText(context);
    final w = Wallet()
      ..items = List.of(file.transactions)
      ..piggyStart = file.piggyStart ?? 0;
    final rows = [
      ('Записей', file.transactions.length.toString()),
      ('Баланс', formatMoney(w.onHand)),
      ('Копилка', formatMoney(w.piggy)),
    ];
    w.dispose();
    final stamp = file.createdAt == null
        ? null
        : 'от ${formatBackupStamp(file.createdAt!)}';

    return SettingsSheet(
      children: [
        const SheetTitle('Восстановить копию?'),
        const SizedBox(height: 14),
        Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        if (stamp != null) ...[
          const SizedBox(height: 2),
          Text(
            stamp,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: cs.onSurface.withValues(alpha: 0.08),
                  ),
                SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      Text(
                        rows[i].$1,
                        style: TextStyle(fontSize: 14, color: muted),
                      ),
                      const Spacer(),
                      Text(
                        rows[i].$2,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SheetNote(
          'Текущие данные заменятся. Перед заменой\nмы сохраним их автоматически.',
        ),
        const SizedBox(height: 16),
        SheetPrimaryButton('Заменить', () => Navigator.pop(context, true)),
        SheetSecondaryButton('Отмена', () => Navigator.pop(context, false)),
      ],
    );
  }
}

class RestoreErrorSheet extends StatelessWidget {
  final String message;
  const RestoreErrorSheet({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SettingsSheet(
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: kAmberGradient,
              ),
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SheetTitle('Файл не подходит'),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: mutedText(context)),
        ),
        const SizedBox(height: 14),
        Text(
          'Твои данные не изменились',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        SheetPrimaryButton(
          'Выбрать другой файл',
          () => Navigator.pop(context, true),
        ),
        SheetSecondaryButton('Закрыть', () => Navigator.pop(context, false)),
      ],
    );
  }
}
