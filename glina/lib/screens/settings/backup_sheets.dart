import 'package:flutter/material.dart';

import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/settings/settings_glyph.dart';
import 'package:money_app/screens/settings/settings_page.dart';
import 'package:money_app/screens/settings/settings_sheet.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

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
    final g = context.g;
    final w = Wallet()
      ..items = List.of(file.transactions)
      ..piggyStart = file.piggyStart ?? 0;
    final field = Color.alphaBlend(
      g.ink.withValues(alpha: g.dark ? 0.10 : 0.06),
      g.surf,
    );
    final rows = [
      ('Записей', file.transactions.length.toString(), false),
      ('Баланс', formatMoney(w.onHand), true),
      ('Копилка', formatMoney(w.piggy), true),
    ];
    w.dispose();
    final stamp = file.createdAt == null
        ? null
        : 'от ${formatBackupStamp(file.createdAt!)}';

    return SettingsSheet(
      children: [
        SizedBox(
          height: 28,
          child: Transform.translate(
            offset: const Offset(0, -8),
            child: Text(
              'Восстановить копию?',
              style: golos(20, 700, color: g.ink),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Glina.tint(g.accent, g.surf),
                ),
                child: const SettingsGlyph(SettingsGlyphKind.file),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 18,
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: golos(14, 600, color: g.ink, height: 1.28),
                      ),
                    ),
                    if (stamp != null)
                      SizedBox(
                        height: 18,
                        child: Text(
                          stamp,
                          style: golos(13, 500, color: g.ink2, height: 1.38),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 132,
          decoration: BoxDecoration(
            color: field,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              for (var i = 0; i < rows.length; i++)
                Positioned(
                  left: 16,
                  right: 16,
                  top: i * 44.0,
                  height: 44,
                  child: Row(
                    children: [
                      Text(rows[i].$1, style: golos(14, 500, color: g.ink2)),
                      const Spacer(),
                      Text(
                        rows[i].$2,
                        style: rows[i].$3
                            ? literata(17, w: 600, color: g.ink)
                            : golos(15, 700, color: g.ink),
                      ),
                    ],
                  ),
                ),
              for (var i = 1; i < rows.length; i++)
                Positioned(
                  left: 16,
                  right: 16,
                  top: i * 44.0 - 1,
                  height: 1,
                  child: ColoredBox(color: g.line),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 56,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Glina.tint(g.accent, g.surf),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in const [
                'Текущие данные заменятся. Перед заменой',
                'мы сохраним их автоматически.',
              ])
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    line,
                    maxLines: 1,
                    style: golos(13, 500, color: g.ink, height: 1.38),
                  ),
                ),
            ],
          ),
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
    final g = context.g;
    return SettingsSheet(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Glina.tint(g.accent, g.surf),
            ),
            child: const SettingsGlyph(SettingsGlyphKind.bang, size: 56),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 28,
          child: Transform.translate(
            offset: const Offset(0, -7.5),
            child: Text(
              'Файл не подходит',
              textAlign: TextAlign.center,
              style: golos(20, 700, color: g.ink),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Transform.translate(
          offset: const Offset(0, -3.5),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: golos(14, 500, color: g.ink2, height: 1.3),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 20,
          child: Text(
            'Твои данные не изменились',
            textAlign: TextAlign.center,
            style: golos(13, 600, color: g.ink),
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
