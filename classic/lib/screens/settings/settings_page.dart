import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/settings/appearance_sheets.dart';
import 'package:money_app/screens/settings/backup_sheets.dart';
import 'package:money_app/screens/settings/settings_widgets.dart';
import 'package:money_app/services/backup_io.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/services/tiyn_home_widget.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/widgets/glass_sheet.dart';
import 'package:money_app/widgets/round_icon_button.dart';

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

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

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

  Future<void> _pickTheme() =>
      showGlassSheet<void>(context, ThemeSheet(onChanged: _themeChanged));

  Future<void> _pickAccent() =>
      showGlassSheet<void>(context, AccentSheet(onChanged: _themeChanged));

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

  Future<void> _reload() async {
    await appTheme.load();
    await Reminder.reloadSettings();
    // Also reschedules the reminder and redraws the widget.
    await widget.wallet.load();
  }

  Future<void> _replace(BackupFile file) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await Backup.restore(prefs, file);
    } catch (_) {
      try {
        await _reload();
      } catch (_) {}
      if (mounted) _snack('Не удалось восстановить. Данные не изменились');
      return;
    }
    await _reload();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = mutedText(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                            RoundIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Настройки',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      const SettingsSectionHead('Оформление'),
                      ListenableBuilder(
                        listenable: appTheme,
                        builder: (context, _) => SettingsCard(
                          children: [
                            SettingsRow(
                              onTap: _pickTheme,
                              icon: Icons.contrast_rounded,
                              label: 'Тема',
                              trailing: Text(
                                themeModeLabel(appTheme.mode),
                                style: TextStyle(fontSize: 14, color: muted),
                              ),
                            ),
                            SettingsRow(
                              onTap: _pickAccent,
                              icon: Icons.palette_outlined,
                              label: 'Акцент',
                              trailing: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentOf(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SettingsSectionHead('Напоминание'),
                      ValueListenableBuilder(
                        valueListenable: Reminder.settings,
                        builder: (context, s, _) {
                          final (on, h, m) = s;
                          return SettingsCard(
                            children: [
                              SettingsRow(
                                onTap: _pickTime,
                                icon: Icons.notifications_none_rounded,
                                label: 'Напоминать в ${_two(h)}:${_two(m)}',
                                trailing: Switch(
                                  value: on,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  activeTrackColor: accentOf(context),
                                  activeThumbColor: Colors.white,
                                  onChanged: _toggleReminder,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const SettingsSectionHead('Данные'),
                      SettingsCard(
                        children: [
                          SettingsRow(
                            onTap: _saveCopy,
                            icon: Icons.file_download_outlined,
                            label: 'Сохранить копию',
                          ),
                          SettingsRow(
                            onTap: _restoreFlow,
                            icon: Icons.file_upload_outlined,
                            label: 'Восстановить из копии',
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                        child: _lastBackup == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Копий ещё не было',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Сохрани копию, чтобы не потерять записи',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Последняя копия: ${formatBackupStamp(_lastBackup!)}',
                                style: TextStyle(fontSize: 13, color: muted),
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
