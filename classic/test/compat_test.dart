import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/category.dart';
import 'package:money_app/data/period.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/stats/category_stats.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/theme/app_theme.dart';

/// Backup written by the other Tiyn style (accent `clay`, category «Хобби»
/// that this style has never had).
String glinaFile() =>
    File('test/fixtures/glina_backup.json').readAsStringSync();

Map<String, dynamic> dataOf(String text) =>
    (jsonDecode(text) as Map)['data'] as Map<String, dynamic>;

void main() {
  test('файл Глины читается, восстанавливается и сохраняется заново', () async {
    SharedPreferences.setMockInitialValues({
      'transactions': '[]',
      'accent': 'blue',
    });
    final p = await SharedPreferences.getInstance();
    await Backup.restore(p, Backup.parse(glinaFile()));

    expect(p.getString('theme_mode'), 'dark');
    expect(p.getString('accent'), 'red');
    expect(p.getInt('piggy_start'), 19000);
    expect(p.getString('last_cat_expense'), 'Кафе');
    expect(p.getBool('remind_on'), isTrue);
    expect(p.getInt('remind_h'), 23);

    final again = Backup.snapshot(p, DateTime(2026, 11, 14, 17, 55));
    expect(again['app'], 'tiyn');
    expect(again['version'], 1);
    final want = dataOf(glinaFile())..['accent'] = 'red';
    expect(again['data'], want);
  });

  test('файл классики по структуре совпадает с файлом Глины', () async {
    SharedPreferences.setMockInitialValues({
      'transactions': jsonEncode([
        {
          'id': 'a',
          'amount': 100,
          'kind': 'expense',
          'isIncome': false,
          'category': 'Еда',
          'note': '',
          'date': '2026-11-12T12:00:00.000',
        },
      ]),
      'accent': 'orange',
    });
    final p = await SharedPreferences.getInstance();
    final mine = Backup.snapshot(p, DateTime(2026, 11, 14, 17, 55));
    final theirs = jsonDecode(glinaFile()) as Map<String, dynamic>;
    expect(mine.keys.toSet(), theirs.keys.toSet());
    expect(
      (mine['data'] as Map).keys.toSet(),
      (theirs['data'] as Map).keys.toSet(),
    );
    final tx = ((mine['data'] as Map)['transactions'] as List).first as Map;
    final theirTx =
        ((theirs['data'] as Map)['transactions'] as List).first as Map;
    expect(tx.keys.toSet(), theirTx.keys.toSet());
  });

  test('неизвестная категория считается как «Другое»', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await Backup.restore(p, Backup.parse(glinaFile()));
    final w = Wallet();
    await w.load();
    expect(findCategory('Хобби', false).name, 'Другое');
    final period = StatPeriod.month(DateTime(2026, 11), DateTime(2026, 11, 30));
    final stats = expensesByCategory(w.items, period);
    expect(stats.map((e) => e.key.name), ['Кафе', 'Другое']);
    expect(stats.last.value, 700);
    w.dispose();
  });

  test(
    'ключи Глины в prefs терпимы: Wallet и Reminder читают без ошибок',
    () async {
      SharedPreferences.setMockInitialValues({
        'last_cat_expense': 'Кафе',
        'last_cat_income': 'Стипендия',
        'restore_undo': '{"app":"tiyn","version":1,"data":{}}',
        'last_backup_at': '2026-11-14T17:55:00.000',
        'theme_mode': 'dark',
        'accent': 'clay',
      });
      final w = Wallet();
      await w.load();
      expect(w.items, isEmpty);
      await Reminder.reloadSettings();
      expect(Reminder.settings.value, (false, 21, 0));
      final t = AppTheme();
      await t.load();
      expect(t.accent, AccentId.red);
      w.dispose();
    },
  );

  test(
    'перезагрузка Wallet после восстановления сбрасывает отсутствующее',
    () async {
      SharedPreferences.setMockInitialValues({
        'transactions': jsonEncode(dataOf(glinaFile())['transactions']),
        'piggy_start': 500,
      });
      final w = Wallet();
      await w.load();
      expect(w.items.length, 4);
      final p = await SharedPreferences.getInstance();
      await Backup.restore(
        p,
        Backup.parse(
          jsonEncode({
            'app': 'tiyn',
            'version': 1,
            'data': {'transactions': []},
          }),
        ),
      );
      await w.load();
      expect(w.items, isEmpty);
      expect(w.piggyStart, 0);
      expect(w.plans, isEmpty);
      w.dispose();
    },
  );
}
