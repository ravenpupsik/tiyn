import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/data/txn.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/tokens.dart';

const kBackupVersion = 1;

class BackupKeys {
  static const transactions = 'transactions';
  static const plans = 'plans';
  static const piggyStart = 'piggy_start';
  static const lastCatExpense = 'last_cat_expense';
  static const lastCatIncome = 'last_cat_income';
  static const remindOn = 'remind_on';
  static const remindH = 'remind_h';
  static const remindM = 'remind_m';
  static const themeMode = ThemeKeys.themeMode;
  static const accent = ThemeKeys.accent;

  /// Service keys are not written to the backup file.
  static const lastBackupAt = 'last_backup_at';
  static const restoreUndo = 'restore_undo';
}

enum BackupErrorKind { notTiyn, newer, corrupt, unreadable }

class BackupError implements Exception {
  final BackupErrorKind kind;
  const BackupError(this.kind);

  String get message => switch (kind) {
    BackupErrorKind.notTiyn => 'Это не копия Tiyn',
    BackupErrorKind.newer => 'Копия из новой версии Tiyn. Обнови приложение',
    BackupErrorKind.corrupt => 'Файл повреждён',
    BackupErrorKind.unreadable => 'Не удалось прочитать файл',
  };

  @override
  String toString() => 'BackupError(${kind.name})';
}

class BackupWriteError implements Exception {
  final String what;
  const BackupWriteError(this.what);
  @override
  String toString() => 'BackupWriteError($what)';
}

class BackupFile {
  final DateTime? createdAt;
  final List<Txn> transactions;
  final List<Map<String, dynamic>> plans;
  final int? piggyStart;
  final String? lastCatExpense, lastCatIncome;
  final bool? remindOn;
  final int? remindH, remindM;

  final String? themeMode, accent;

  const BackupFile({
    required this.createdAt,
    required this.transactions,
    required this.plans,
    required this.piggyStart,
    required this.lastCatExpense,
    required this.lastCatIncome,
    required this.remindOn,
    required this.remindH,
    required this.remindM,
    this.themeMode,
    this.accent,
  });
}

class Backup {
  Backup._();

  static String fileName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'tiyn_${now.year}-${two(now.month)}-${two(now.day)}.json';
  }

  static String isoWithOffset(DateTime d) {
    final l = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final off = l.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final a = off.abs();
    final head = l.toIso8601String().split('.').first;
    return '$head$sign${two(a.inHours)}:${two(a.inMinutes % 60)}';
  }

  /// Entries go through the model so old entries without `kind` get one.
  static Map<String, dynamic> snapshot(SharedPreferences p, DateTime now) {
    final rawTx = p.getString(BackupKeys.transactions);
    final rawPlans = p.getString(BackupKeys.plans);
    final txs = rawTx == null
        ? <Map<String, dynamic>>[]
        : [
            for (final e in jsonDecode(rawTx) as List)
              Txn.fromJson(e as Map<String, dynamic>).toJson(),
          ];
    final plans = rawPlans == null
        ? <Map<String, dynamic>>[]
        : [
            for (final e in jsonDecode(rawPlans) as List)
              _normPlan(e as Map<String, dynamic>),
          ];
    return {
      'app': 'tiyn',
      'version': kBackupVersion,
      'createdAt': isoWithOffset(now),
      'data': {
        'transactions': txs,
        'plans': plans,
        'piggyStart': p.getInt(BackupKeys.piggyStart) ?? 0,
        'lastCatExpense': p.getString(BackupKeys.lastCatExpense),
        'lastCatIncome': p.getString(BackupKeys.lastCatIncome),
        'remind': {
          'on': p.getBool(BackupKeys.remindOn) ?? false,
          'h': p.getInt(BackupKeys.remindH) ?? 21,
          'm': p.getInt(BackupKeys.remindM) ?? 0,
        },
        'themeMode': parseThemeMode(p.getString(BackupKeys.themeMode)).name,
        'accent': AccentId.parse(p.getString(BackupKeys.accent)).id,
      },
    };
  }

  static Map<String, dynamic> _normPlan(Map<String, dynamic> j) => {
    'id': j['id'] as String,
    'title': (j['title'] ?? '') as String,
    'amount': j['amount'] as int,
    'category': (j['category'] ?? '') as String,
    'due': j['due'],
  };

  static String encode(Map<String, dynamic> map) =>
      const JsonEncoder.withIndent('  ').convert(map);

  static Uint8List encodeBytes(Map<String, dynamic> map) =>
      Uint8List.fromList(utf8.encode(encode(map)));

  static BackupFile parseBytes(List<int> bytes) {
    var raw = bytes;
    // Some editors prepend a BOM.
    if (raw.length >= 3 && raw[0] == 0xEF && raw[1] == 0xBB && raw[2] == 0xBF) {
      raw = raw.sublist(3);
    }
    final String text;
    try {
      text = utf8.decode(raw);
    } on FormatException {
      throw const BackupError(BackupErrorKind.notTiyn);
    }
    return parse(text);
  }

  static BackupFile parse(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const BackupError(BackupErrorKind.notTiyn);
    }
    if (root is! Map || root['app'] != 'tiyn') {
      throw const BackupError(BackupErrorKind.notTiyn);
    }
    final version = root['version'];
    if (version is! int || version < 1) {
      throw const BackupError(BackupErrorKind.corrupt);
    }
    if (version > kBackupVersion) {
      throw const BackupError(BackupErrorKind.newer);
    }
    try {
      return _parseData(root);
    } on BackupError {
      rethrow;
    } catch (_) {
      throw const BackupError(BackupErrorKind.corrupt);
    }
  }

  static BackupError get _bad => const BackupError(BackupErrorKind.corrupt);

  static BackupFile _parseData(Map root) {
    final data = root['data'];
    if (data is! Map) throw _bad;

    DateTime? createdAt;
    final c = root['createdAt'];
    if (c is String) createdAt = DateTime.tryParse(c)?.toLocal();

    final txRaw = data['transactions'];
    if (txRaw != null && txRaw is! List) throw _bad;
    final txs = <Txn>[];
    final ids = <String>{};
    for (final e in (txRaw as List? ?? const [])) {
      if (e is! Map) throw _bad;
      final id = e['id'], amount = e['amount'], kind = e['kind'];
      final date = e['date'];
      if (id is! String || id.isEmpty || !ids.add(id)) throw _bad;
      if (amount is! int || amount < 0) throw _bad;
      if (kind is! String || !TxnKind.values.any((k) => k.name == kind)) {
        throw _bad;
      }
      if (date is! String || DateTime.tryParse(date) == null) throw _bad;
      final category = e['category'], note = e['note'];
      if (category != null && category is! String) throw _bad;
      if (note != null && note is! String) throw _bad;
      txs.add(
        Txn(
          id: id,
          amount: amount,
          kind: TxnKind.values.firstWhere((k) => k.name == kind),
          category: (category ?? '') as String,
          note: (note ?? '') as String,
          date: DateTime.parse(date),
        ),
      );
    }

    final plansRaw = data['plans'];
    if (plansRaw != null && plansRaw is! List) throw _bad;
    final plans = <Map<String, dynamic>>[];
    final planIds = <String>{};
    for (final e in (plansRaw as List? ?? const [])) {
      if (e is! Map) throw _bad;
      final id = e['id'], amount = e['amount'], due = e['due'];
      if (id is! String || id.isEmpty || !planIds.add(id)) throw _bad;
      if (amount is! int || amount < 0) throw _bad;
      if (due != null && (due is! String || DateTime.tryParse(due) == null)) {
        throw _bad;
      }
      final title = e['title'], category = e['category'];
      if (title != null && title is! String) throw _bad;
      if (category != null && category is! String) throw _bad;
      plans.add({
        'id': id,
        'title': title ?? '',
        'amount': amount,
        'category': category ?? '',
        'due': due,
      });
    }

    final piggy = data['piggyStart'];
    if (piggy != null && piggy is! int) throw _bad;
    final lce = data['lastCatExpense'], lci = data['lastCatIncome'];
    if (lce != null && lce is! String) throw _bad;
    if (lci != null && lci is! String) throw _bad;

    bool? on;
    int? h, m;
    final remind = data['remind'];
    if (remind != null) {
      if (remind is! Map) throw _bad;
      final ro = remind['on'], rh = remind['h'], rm = remind['m'];
      if (ro != null && ro is! bool) throw _bad;
      if (rh != null && (rh is! int || rh < 0 || rh > 23)) throw _bad;
      if (rm != null && (rm is! int || rm < 0 || rm > 59)) throw _bad;
      on = ro as bool?;
      h = rh as int?;
      m = rm as int?;
    }

    // Theme and accent missing from the file keep their current values; an
    // unknown value falls back to the system theme and the clay accent.
    final tm = data['themeMode'], ac = data['accent'];

    return BackupFile(
      createdAt: createdAt,
      transactions: txs,
      plans: plans,
      piggyStart: piggy as int?,
      lastCatExpense: lce as String?,
      lastCatIncome: lci as String?,
      remindOn: on,
      remindH: h,
      remindM: m,
      themeMode: tm == null ? null : parseThemeMode(tm).name,
      accent: ac == null ? null : AccentId.parse(ac).id,
    );
  }

  /// Keys missing from the backup are reset to defaults (removed). Any prefs
  /// failure throws.
  static Future<void> _write(SharedPreferences p, BackupFile f) async {
    Future<void> put(String key, Object? value) async {
      final ok = switch (value) {
        null => await p.remove(key),
        String s => await p.setString(key, s),
        int i => await p.setInt(key, i),
        bool b => await p.setBool(key, b),
        _ => false,
      };
      if (!ok) throw BackupWriteError(key);
    }

    await put(
      BackupKeys.transactions,
      jsonEncode([for (final t in f.transactions) t.toJson()]),
    );
    await put(BackupKeys.plans, jsonEncode(f.plans));
    await put(BackupKeys.piggyStart, f.piggyStart);
    await put(BackupKeys.lastCatExpense, f.lastCatExpense);
    await put(BackupKeys.lastCatIncome, f.lastCatIncome);
    await put(BackupKeys.remindOn, f.remindOn);
    await put(BackupKeys.remindH, f.remindH);
    await put(BackupKeys.remindM, f.remindM);
    if (f.themeMode != null) await put(BackupKeys.themeMode, f.themeMode);
    if (f.accent != null) await put(BackupKeys.accent, f.accent);
  }

  /// Saves the current state to `restore_undo` (a single, latest auto-copy)
  /// before replacing. If writing fails, data is rolled back from it and the
  /// exception is rethrown.
  static Future<void> restore(
    SharedPreferences p,
    BackupFile f, {
    DateTime? now,
  }) async {
    final String undo;
    try {
      undo = encode(snapshot(p, now ?? DateTime.now()));
    } catch (_) {
      throw const BackupWriteError('snapshot');
    }
    if (!await p.setString(BackupKeys.restoreUndo, undo)) {
      throw const BackupWriteError(BackupKeys.restoreUndo);
    }
    try {
      await _write(p, f);
    } catch (e) {
      try {
        await _write(p, parse(undo));
      } catch (_) {
        // Rollback failed too: nothing more can be done.
      }
      rethrow;
    }
  }

  static bool hasUndo(SharedPreferences p) =>
      p.getString(BackupKeys.restoreUndo) != null;

  /// Returns data from `restore_undo`; false if there is no auto-copy.
  static Future<bool> undo(SharedPreferences p) async {
    final raw = p.getString(BackupKeys.restoreUndo);
    if (raw == null) return false;
    await _write(p, parse(raw));
    return true;
  }
}
