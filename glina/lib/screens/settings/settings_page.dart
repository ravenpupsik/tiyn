import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/settings/appearance_sheets.dart';
import 'package:money_app/screens/settings/backup_sheets.dart';
import 'package:money_app/screens/settings/backup_snacks.dart';
import 'package:money_app/screens/settings/settings_glyph.dart';
import 'package:money_app/screens/settings/settings_widgets.dart';
import 'package:money_app/services/backup_io.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/services/tiyn_home_widget.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/widgets/glass_sheet.dart';
import 'package:money_app/widgets/pressable.dart';

class SettingsPage extends StatefulWidget {
  final Wallet wallet;
  const SettingsPage({super.key, required this.wallet});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  DateTime? _lastBackup;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(BackupKeys.lastBackupAt);
    if (!mounted) return;
    setState(() => _lastBackup = raw == null ? null : DateTime.tryParse(raw));
  }

  double get _snackBottom => 8;

  void _snack(String text) =>
      showBackupSnack(context, text, bottom: _snackBottom);

  Future<void> _toggleReminder(bool v) async {
    HapticFeedback.selectionClick();
    final ok = await Reminder.setOn(v);
    if (!ok && mounted) {
      _snack('Разреши уведомления для Tiyn в настройках телефона');
    }
  }

  Future<void> _pickTime() async {
    if (!Reminder.on) await _toggleReminder(true);
    if (!mounted || !Reminder.on) return;
    await showGlassSheet<void>(context, const ReminderTimeSheet());
  }

  Future<void> _pickTheme() async {
    await showGlassSheet<void>(context, ThemeSheet(onChanged: _themeChanged));
  }

  Future<void> _pickAccent() async {
    await showGlassSheet<void>(context, AccentSheet(onChanged: _themeChanged));
  }

  void _themeChanged() {
    TiynHomeWidget.update(widget.wallet);
    Reminder.refresh();
  }

  Future<void> _saveCopy() async {
    if (_busy) return;
    _busy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final Uint8List bytes;
      try {
        bytes = Backup.encodeBytes(Backup.snapshot(prefs, now));
      } catch (_) {
        if (mounted) _snack('Не удалось сохранить копию');
        return;
      }
      bool saved;
      try {
        saved = await BackupIO.saveFile(Backup.fileName(now), bytes);
      } catch (_) {
        if (mounted) _snack('Не удалось сохранить копию');
        return;
      }
      if (!saved) return;
      await prefs.setString(BackupKeys.lastBackupAt, now.toIso8601String());
      if (!mounted) return;
      setState(() => _lastBackup = now);
      _snack('Копия сохранена');
    } finally {
      _busy = false;
    }
  }

  Future<void> _restoreFlow() async {
    if (_busy) return;
    _busy = true;
    try {
      while (true) {
        ({String name, Uint8List bytes})? picked;
        try {
          picked = await BackupIO.pickFile();
        } catch (_) {
          if (!mounted) return;
          final again = await _showError(
            const BackupError(BackupErrorKind.unreadable),
          );
          if (again == true && mounted) continue;
          return;
        }
        if (picked == null || !mounted) return;
        final BackupFile file;
        try {
          file = Backup.parseBytes(picked.bytes);
        } on BackupError catch (e) {
          final again = await _showError(e);
          if (again == true && mounted) continue;
          return;
        }
        if (!mounted) return;
        final replace = await showGlassSheet<bool>(
          context,
          ConfirmRestoreSheet(fileName: picked.name, file: file),
        );
        if (replace == true && mounted) await _replace(file);
        return;
      }
    } finally {
      _busy = false;
    }
  }

  Future<bool?> _showError(BackupError e) =>
      showGlassSheet<bool>(context, RestoreErrorSheet(message: e.message));

  Future<void> _replace(BackupFile file) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await Backup.restore(prefs, file);
    } catch (_) {
      try {
        await appTheme.load();
        await Reminder.reloadSettings();
        await widget.wallet.load();
      } catch (_) {}
      if (mounted) _snack('Не удалось восстановить. Данные не изменились');
      return;
    }
    await appTheme.load();
    await Reminder.reloadSettings();
    await widget.wallet
        .load(); // recreates the reminder and refreshes the widget
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(context),
      child: Scaffold(
        backgroundColor: g.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: Backdrop()),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Row(
                          children: [
                            Pressable(
                              onTap: () => Navigator.pop(context),
                              child: Semantics(
                                button: true,
                                label: 'Назад',
                                excludeSemantics: true,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: g.surf,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: g.ink,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Настройки',
                              style: golos(22, 700, color: g.ink),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const SettingsSectionHead('Оформление'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SettingsCard(
                          child: ListenableBuilder(
                            listenable: appTheme,
                            builder: (context, _) => Column(
                              children: [
                                SettingsRow(
                                  onTap: _pickTheme,
                                  icon: Icon(
                                    Icons.contrast_rounded,
                                    size: 22,
                                    color: g.accentText,
                                  ),
                                  label: 'Тема',
                                  trailing: Text(
                                    themeModeLabel(appTheme.mode),
                                    style: golos(14, 500, color: g.ink2),
                                  ),
                                ),
                                Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(
                                    left: 62,
                                    right: 16,
                                  ),
                                  color: g.line,
                                ),
                                SettingsRow(
                                  onTap: _pickAccent,
                                  icon: Icon(
                                    Icons.palette_outlined,
                                    size: 22,
                                    color: g.accentText,
                                  ),
                                  label: 'Акцент',
                                  trailing: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: g.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SettingsSectionHead('Напоминание'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SettingsCard(
                          child: ValueListenableBuilder(
                            valueListenable: Reminder.settings,
                            builder: (context, s, _) {
                              final (on, h, m) = s;
                              return SettingsRow(
                                onTap: _pickTime,
                                icon: Icon(
                                  Icons.notifications_none_outlined,
                                  size: 22,
                                  color: g.accentText,
                                ),
                                label: 'Напоминать в ${_two(h)}:${_two(m)}',
                                trailing: Switch(
                                  value: on,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  activeTrackColor: g.accent,
                                  activeThumbColor: g.onAccent,
                                  onChanged: _toggleReminder,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SettingsSectionHead('Данные'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SettingsCard(
                          child: Column(
                            children: [
                              SettingsRow(
                                onTap: _saveCopy,
                                icon: const SettingsGlyph(
                                  SettingsGlyphKind.down,
                                ),
                                label: 'Сохранить копию',
                              ),
                              Container(
                                height: 1,
                                margin: const EdgeInsets.only(
                                  left: 62,
                                  right: 16,
                                ),
                                color: g.line,
                              ),
                              SettingsRow(
                                onTap: _restoreFlow,
                                icon: const SettingsGlyph(SettingsGlyphKind.up),
                                label: 'Восстановить из копии',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 11, 20, 24),
                        child: _lastBackup == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Копий ещё не было',
                                    style: golos(13, 600, color: g.ink2),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Сохрани копию, чтобы не потерять записи',
                                    style: golos(13, 500, color: g.ink2),
                                  ),
                                ],
                              )
                            : Text(
                                'Последняя копия: ${formatBackupStamp(_lastBackup!)}',
                                style: golos(13, 500, color: g.ink2),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatBackupStamp(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final l = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${formatShortDate(l, now: n)}, ${two(l.hour)}:${two(l.minute)}';
}
