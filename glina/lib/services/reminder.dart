import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:money_app/data/txn.dart';
import 'package:money_app/theme/glina_theme.dart';

/// Evening reminder "Did you log today's spending?". Notifications are
/// scheduled 14 days ahead; today's is skipped if there is already an entry
/// today. Rescheduled on every change and on start, so no background work is
/// needed. After a reboot the plugin restores them (receiver in
/// AndroidManifest).
class Reminder {
  /// Enabled in main(); tests have no notifications.
  static bool platformEnabled = false;
  static bool launchedFromTap = false;

  static final openAdd = ValueNotifier<int>(0);

  static final settings = ValueNotifier<(bool, int, int)>((false, 21, 0));
  static bool get on => settings.value.$1;
  static int get hour => settings.value.$2;
  static int get minute => settings.value.$3;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _baseId = 100;
  static const _days = 14;
  static List<Txn> _lastItems = const [];

  static NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      'evening_reminder',
      'Вечернее напоминание',
      channelDescription: 'Раз в день напоминает записать траты',
      icon: 'ic_stat_tiyn',
      color: currentAccentLight,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  static Future<void> refresh() => reschedule(_lastItems);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    settings.value = (
      prefs.getBool('remind_on') ?? false,
      prefs.getInt('remind_h') ?? 21,
      prefs.getInt('remind_m') ?? 0,
    );
    if (!platformEnabled) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Almaty'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_tiyn'),
      ),
      onDidReceiveNotificationResponse: (_) => openAdd.value++,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    launchedFromTap = launch?.didNotificationLaunchApp ?? false;
  }

  static Future<bool> setOn(bool value) async {
    if (value && platformEnabled) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission() ?? true;
      if (!granted) return false;
    }
    settings.value = (value, hour, minute);
    await _store();
    await reschedule(_lastItems);
    return true;
  }

  static Future<void> reloadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    settings.value = (
      prefs.getBool('remind_on') ?? false,
      prefs.getInt('remind_h') ?? 21,
      prefs.getInt('remind_m') ?? 0,
    );
  }

  static Future<void> setTime(int h, int m) async {
    settings.value = (on, h, m);
    await _store();
    await reschedule(_lastItems);
  }

  static Future<void> _store() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remind_on', on);
    await prefs.setInt('remind_h', hour);
    await prefs.setInt('remind_m', minute);
  }

  static bool hasToday(List<Txn> items, DateTime now) => items.any(
    (t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day,
  );

  static List<int> plannedDays(List<Txn> items, DateTime now) {
    final days = <int>[];
    for (var d = 0; d < _days; d++) {
      if (d == 0) {
        final todayAt = DateTime(now.year, now.month, now.day, hour, minute);
        if (!todayAt.isAfter(now) || hasToday(items, now)) continue;
      }
      days.add(d);
    }
    return days;
  }

  static Future<void> reschedule(List<Txn> items) async {
    _lastItems = items;
    if (!platformEnabled) return;
    try {
      for (var i = 0; i < _days; i++) {
        await _plugin.cancel(id: _baseId + i);
      }
      if (!on) return;
      final now = tz.TZDateTime.now(tz.local);
      for (final d in plannedDays(items, now)) {
        final at = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + d,
          hour,
          minute,
        );
        await _plugin.zonedSchedule(
          id: _baseId + d,
          scheduledDate: at,
          notificationDetails: _details,
          // Inexact schedule: off by a couple of minutes, but needs no
          // exact-alarm permission.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Tiyn',
          body: 'Записал траты за сегодня?',
        );
      }
    } catch (_) {
      // Notification failures must not crash the app.
    }
  }
}
