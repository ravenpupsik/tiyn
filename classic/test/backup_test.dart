import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

import 'package:money_app/app.dart';
import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/plan.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/services/backup_io.dart';
import 'package:money_app/services/reminder.dart';

Txn tx(
  String id,
  int amount,
  DateTime d,
  String cat,
  TxnKind kind, [
  String note = '',
]) =>
    Txn(id: id, amount: amount, kind: kind, category: cat, note: note, date: d);

Map<String, Object> sampleA() {
  final items = [
    tx('1', 36000, DateTime(2026, 11, 10, 12), 'Стипендия', TxnKind.income),
    tx(
      '2',
      900,
      DateTime(2026, 11, 12, 14, 12),
      'Кафе',
      TxnKind.expense,
      'кофе',
    ),
    tx('3', 5000, DateTime(2026, 11, 12, 15), 'Копилка', TxnKind.toPiggy),
    tx('4', 1200, DateTime(2026, 11, 13, 9, 30), 'Еда', TxnKind.expense),
  ];
  return {
    'transactions': jsonEncode([for (final t in items) t.toJson()]),
    'plans': jsonEncode([
      const Plan(
        id: 'p1',
        title: 'Зубной',
        amount: 15000,
        category: 'Другое',
      ).toJson(),
      Plan(
        id: 'p2',
        title: '',
        amount: 700,
        due: DateTime(2026, 12, 1),
      ).toJson(),
    ]),
    'piggy_start': 19000,
    'last_cat_expense': 'Кафе',
    'last_cat_income': 'Стипендия',
    'remind_on': true,
    'remind_h': 21,
    'remind_m': 30,
  };
}

Map<String, Object> sampleB() => {
  'transactions': jsonEncode([
    tx('x', 111, DateTime(2026, 1, 1, 8), 'Еда', TxnKind.expense).toJson(),
  ]),
  'piggy_start': 5,
  'remind_on': false,
  'remind_h': 8,
  'remind_m': 5,
};

Map<String, Object?> dump(SharedPreferences p) => {
  for (final k in p.getKeys().toList()..sort()) k: p.get(k),
};

Future<SharedPreferences> prefsWith(Map<String, Object> v) async {
  SharedPreferences.setMockInitialValues(v);
  return SharedPreferences.getInstance();
}

/// Backup data without createdAt (for comparison).
Map<String, dynamic> dataOf(SharedPreferences p) =>
    Backup.snapshot(p, DateTime(2026, 11, 14, 17, 55))['data']
        as Map<String, dynamic>;

void main() {
  breathingEnabled = false;
  group('формат файла', () {
    test('имя и createdAt с часовым поясом', () {
      expect(Backup.fileName(DateTime(2026, 11, 4)), 'tiyn_2026-11-04.json');
      final s = Backup.isoWithOffset(DateTime(2026, 11, 14, 17, 55));
      expect(s, matches(r'^2026-11-14T17:55:00[+-]\d\d:\d\d$'));
    });

    test('массивы объектов, не строки; ключи по ТЗ', () async {
      final p = await prefsWith(sampleA());
      final m = Backup.snapshot(p, DateTime(2026, 11, 14, 17, 55));
      expect(m['app'], 'tiyn');
      expect(m['version'], 1);
      final d = m['data'] as Map;
      expect(d['transactions'], isA<List>());
      expect((d['transactions'] as List).first, isA<Map>());
      expect(d['plans'], isA<List>());
      expect(d['piggyStart'], 19000);
      expect(d['lastCatExpense'], 'Кафе');
      expect(d['remind'], {'on': true, 'h': 21, 'm': 30});
      // service keys are not written to the file
      expect(Backup.encode(m).contains('restore_undo'), isFalse);
      expect(Backup.encode(m).contains('last_backup_at'), isFalse);
    });

    test('старые записи без kind получают kind', () async {
      final p = await prefsWith({
        'transactions': jsonEncode([
          {
            'id': 'old',
            'amount': 100,
            'isIncome': true,
            'category': 'Стипендия',
            'note': '',
            'date': DateTime(2026, 1, 1).toIso8601String(),
          },
        ]),
      });
      final txs = dataOf(p)['transactions'] as List;
      expect(txs.single['kind'], 'income');
      // and such a backup passes validation
      Backup.parse(Backup.encode(Backup.snapshot(p, DateTime.now())));
    });

    test('русский текст лежит как есть, UTF-8 с отступами', () async {
      final p = await prefsWith(sampleA());
      final text = utf8.decode(
        Backup.encodeBytes(Backup.snapshot(p, DateTime.now())),
      );
      expect(text, contains('"category": "Кафе"'));
      expect(text, contains('\n  "app": "tiyn"'));
    });
  });

  group('сохранить → восстановить', () {
    test('те же транзакции, планы, piggyStart, remind, категории', () async {
      final a = await prefsWith(sampleA());
      final before = dataOf(a);
      final text = Backup.encode(Backup.snapshot(a, DateTime(2026, 11, 14)));

      // another "phone" with different data
      final b = await prefsWith(sampleB());
      expect(dataOf(b), isNot(before));
      await Backup.restore(b, Backup.parse(text));
      expect(dataOf(b), before);
    });

    test('баланс и Копилка из копии считает Wallet', () async {
      final a = await prefsWith(sampleA());
      final f = Backup.parse(Backup.encode(Backup.snapshot(a, DateTime.now())));
      final w = Wallet()
        ..items = f.transactions
        ..piggyStart = f.piggyStart ?? 0;
      // 36000 − 900 − 5000 − 1200 in hand, 19000 + 5000 in the piggy bank
      expect(w.onHand, 28900);
      expect(w.piggy, 24000);
      expect(f.transactions.length, 4);
      w.dispose();
    });

    test('чего нет в файле, сбрасывается к умолчанию', () async {
      final b = await prefsWith(sampleA());
      final f = Backup.parse(
        jsonEncode({
          'app': 'tiyn',
          'version': 1,
          'createdAt': '2026-11-14T17:55:00+05:00',
          'data': {'transactions': []},
        }),
      );
      await Backup.restore(b, f);
      expect(b.getKeys(), isNot(contains('piggy_start')));
      expect(b.getKeys(), isNot(contains('last_cat_expense')));
      expect(b.getKeys(), isNot(contains('remind_on')));
      expect(b.getString('transactions'), '[]');
      expect(b.getString('plans'), '[]');
    });

    test('createdAt разбирается', () {
      final f = Backup.parse(
        jsonEncode({
          'app': 'tiyn',
          'version': 1,
          'createdAt': '2026-11-14T17:55:00+05:00',
          'data': {},
        }),
      );
      expect(f.createdAt!.toUtc(), DateTime.utc(2026, 11, 14, 12, 55));
    });
  });

  group('ошибки: prefs не меняются', () {
    String file(Map<String, dynamic> m) => jsonEncode(m);
    Map<String, dynamic> good() => {
      'app': 'tiyn',
      'version': 1,
      'createdAt': '2026-11-14T17:55:00+05:00',
      'data': <String, dynamic>{
        'transactions': [
          {
            'id': 'a',
            'amount': 100,
            'kind': 'expense',
            'category': 'Еда',
            'note': '',
            'date': '2026-11-12T12:00:00.000',
          },
        ],
      },
    };

    Future<void> expectRejected(
      String text,
      BackupErrorKind kind, {
      List<int>? bytes,
    }) async {
      final p = await prefsWith(sampleA());
      final before = dump(p);
      Object? err;
      try {
        final f = bytes == null ? Backup.parse(text) : Backup.parseBytes(bytes);
        // would reach the write if validation let it through
        await Backup.restore(p, f);
      } catch (e) {
        err = e;
      }
      expect(err, isA<BackupError>(), reason: text);
      expect((err as BackupError).kind, kind);
      expect(dump(p), before, reason: 'prefs изменились: $text');
    }

    test(
      'не JSON',
      () => expectRejected('привет, это не json', BackupErrorKind.notTiyn),
    );
    test(
      'JSON без app',
      () => expectRejected(
        file({'version': 1, 'data': {}}),
        BackupErrorKind.notTiyn,
      ),
    );
    test(
      'чужой app',
      () => expectRejected(
        file({'app': 'other', 'version': 1, 'data': {}}),
        BackupErrorKind.notTiyn,
      ),
    );
    test(
      'JSON не объект',
      () => expectRejected('[1,2,3]', BackupErrorKind.notTiyn),
    );
    test(
      'бинарный файл',
      () => expectRejected(
        '',
        BackupErrorKind.notTiyn,
        bytes: [0xFF, 0xFE, 0x00, 0x80, 0xC3],
      ),
    );
    test('version 99', () {
      final m = good()..['version'] = 99;
      return expectRejected(file(m), BackupErrorKind.newer);
    });
    test('version не число', () {
      final m = good()..['version'] = 'x';
      return expectRejected(file(m), BackupErrorKind.corrupt);
    });
    test('транзакция без amount', () {
      final m = good();
      (((m['data'] as Map)['transactions'] as List).first as Map).remove(
        'amount',
      );
      return expectRejected(file(m), BackupErrorKind.corrupt);
    });
    test('amount дробный', () {
      final m = good();
      (((m['data'] as Map)['transactions'] as List).first as Map)['amount'] =
          1.5;
      return expectRejected(file(m), BackupErrorKind.corrupt);
    });
    test('транзакция без id / kind / date', () async {
      for (final k in ['id', 'kind', 'date']) {
        final m = good();
        (((m['data'] as Map)['transactions'] as List).first as Map).remove(k);
        await expectRejected(file(m), BackupErrorKind.corrupt);
      }
    });
    test('дата не разбирается', () {
      final m = good();
      (((m['data'] as Map)['transactions'] as List).first as Map)['date'] =
          'вчера';
      return expectRejected(file(m), BackupErrorKind.corrupt);
    });
    test('неизвестный kind', () {
      final m = good();
      (((m['data'] as Map)['transactions'] as List).first as Map)['kind'] =
          'gift';
      return expectRejected(file(m), BackupErrorKind.corrupt);
    });
    test('data не объект / transactions не список / remind плохой', () async {
      await expectRejected(
        file({'app': 'tiyn', 'version': 1, 'data': 5}),
        BackupErrorKind.corrupt,
      );
      final a = good();
      (a['data'] as Map)['transactions'] = 'нет';
      await expectRejected(file(a), BackupErrorKind.corrupt);
      final b = good();
      (b['data'] as Map)['remind'] = {'on': true, 'h': 99, 'm': 0};
      await expectRejected(file(b), BackupErrorKind.corrupt);
    });
    test('план без amount', () {
      final m = good();
      (m['data'] as Map)['plans'] = [
        {'id': 'p', 'title': 'x'},
      ];
      return expectRejected(file(m), BackupErrorKind.corrupt);
    });

    test('BOM в начале файла допустим', () async {
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(file(good()))];
      expect(Backup.parseBytes(bytes).transactions.length, 1);
    });

    test('текст ошибок по ТЗ', () {
      expect(
        const BackupError(BackupErrorKind.notTiyn).message,
        'Это не копия Tiyn',
      );
      expect(
        const BackupError(BackupErrorKind.newer).message,
        'Копия из новой версии Tiyn. Обнови приложение',
      );
      expect(
        const BackupError(BackupErrorKind.corrupt).message,
        'Файл повреждён',
      );
    });
  });

  group('«Отменить»', () {
    test('возвращает прежние данные', () async {
      final other = Backup.parse(
        Backup.encode(
          Backup.snapshot(await prefsWith(sampleB()), DateTime.now()),
        ),
      );
      final q = await prefsWith(sampleA());
      final beforeData = dataOf(q);
      await Backup.restore(q, other);
      expect(dataOf(q), isNot(beforeData));
      expect(Backup.hasUndo(q), isTrue);
      expect(await Backup.undo(q), isTrue);
      expect(dataOf(q), beforeData);
    });

    test('без автокопии отменять нечего', () async {
      final p = await prefsWith(sampleA());
      expect(await Backup.undo(p), isFalse);
    });

    test('запись упала посередине: данные возвращаются', () async {
      SharedPreferences.setMockInitialValues(sampleA());
      final real = await SharedPreferences.getInstance();
      final f = Backup.parse(
        Backup.encode(
          Backup.snapshot(await prefsWith(sampleB()), DateTime.now()),
        ),
      );
      SharedPreferences.setMockInitialValues(sampleA());
      final p = _FailingPrefs(await SharedPreferences.getInstance(), 'plans');
      final beforeData = dataOf(real);
      await expectLater(Backup.restore(p, f), throwsA(isA<BackupWriteError>()));
      expect(dataOf(p), beforeData);
    });
  });

  group('экран: настройки, сохранение, восстановление', () {
    Future<void> setup(WidgetTester tester, Map<String, Object> prefs) async {
      await loadTestFonts();
      tester.view.physicalSize = const Size(360, 800) * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 28 * 3, bottom: 16 * 3);
      tester.view.viewPadding = tester.view.padding;
      addTearDown(() {
        tester.view.reset();
        BackupIO.saveFile = _origSave;
        BackupIO.pickFile = _origPick;
      });
      SharedPreferences.setMockInitialValues(prefs);
      appTheme.reset();
      await Reminder.reloadSettings();
      introEnabled = false;
      await tester.pumpWidget(const TiynApp());
      await tester.pumpAndSettle();
    }

    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Настройки'));
      await tester.pumpAndSettle();
    }

    testWidgets('шестерёнка вместо колокольчика открывает «Настройки»', (
      t,
    ) async {
      await setup(t, sampleA());
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
      expect(find.byIcon(Icons.notifications_active_rounded), findsNothing);
      await openSettings(t);
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Напоминание'), findsOneWidget);
      expect(find.text('Напоминать в 21:30'), findsOneWidget);
      expect(find.text('Данные'), findsOneWidget);
      expect(find.text('Сохранить копию'), findsOneWidget);
      expect(find.text('Восстановить из копии'), findsOneWidget);
      expect(find.text('Копий ещё не было'), findsOneWidget);
      expect(
        find.text('Сохрани копию, чтобы не потерять записи'),
        findsOneWidget,
      );
    });

    testWidgets(
      'сохранение: снекбар и «Последняя копия»; отмена окна ничего не меняет',
      (t) async {
        await setup(t, sampleA());
        await openSettings(t);
        Uint8List? saved;
        String? savedName;
        var result = false;
        BackupIO.saveFile = (name, bytes) async {
          saved = bytes;
          savedName = name;
          return result;
        };
        await t.tap(find.text('Сохранить копию'));
        await t.pumpAndSettle();
        expect(find.text('Копия сохранена'), findsNothing);
        expect(find.textContaining('Последняя копия'), findsNothing);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('last_backup_at'), isNull);

        result = true;
        await t.tap(find.text('Сохранить копию'));
        await t.pumpAndSettle();
        expect(savedName, matches(r'^tiyn_\d{4}-\d\d-\d\d\.json$'));
        expect(Backup.parseBytes(saved!).transactions.length, 4);
        expect(find.text('Копия сохранена'), findsOneWidget);
        expect(find.textContaining('Последняя копия: '), findsOneWidget);
        expect(prefs.getString('last_backup_at'), isNotNull);
      },
    );

    testWidgets('ошибка записи: «Не удалось сохранить копию»', (t) async {
      await setup(t, sampleA());
      await openSettings(t);
      BackupIO.saveFile = (_, _) async => throw Exception('нет места');
      await t.tap(find.text('Сохранить копию'));
      await t.pumpAndSettle();
      expect(find.text('Не удалось сохранить копию'), findsOneWidget);
      expect(find.textContaining('Последняя копия'), findsNothing);
    });

    testWidgets('плохой файл: шторка ошибки, данные не изменились', (t) async {
      await setup(t, sampleA());
      await openSettings(t);
      final prefs = await SharedPreferences.getInstance();
      final before = dump(prefs);
      var picks = 0;
      BackupIO.pickFile = () async {
        picks++;
        return (
          name: 'x.json',
          bytes: Uint8List.fromList(utf8.encode('привет')),
        );
      };
      await t.tap(find.text('Восстановить из копии'));
      await t.pumpAndSettle();
      expect(find.text('Файл не подходит'), findsOneWidget);
      expect(find.text('Это не копия Tiyn'), findsOneWidget);
      expect(find.text('Твои данные не изменились'), findsOneWidget);
      expect(dump(prefs), before);
      // "Choose another file" opens the picker again
      await t.tap(find.text('Выбрать другой файл'));
      await t.pumpAndSettle();
      expect(picks, 2);
      await t.tap(find.text('Закрыть'));
      await t.pumpAndSettle();
      expect(find.text('Файл не подходит'), findsNothing);
      expect(dump(prefs), before);
    });

    testWidgets('хороший файл: подтверждение, замена, снекбар, «Отменить»', (
      t,
    ) async {
      await setup(t, sampleA());
      await openSettings(t);
      final prefs = await SharedPreferences.getInstance();
      final beforeData = dataOf(prefs);
      final other = await prefsWith(sampleB());
      final bytes = Backup.encodeBytes(
        Backup.snapshot(other, DateTime(2026, 11, 14, 17, 55)),
      );
      // app prefs are unchanged (prefsWith replaced them), restore them
      SharedPreferences.setMockInitialValues(sampleA());
      final app = await SharedPreferences.getInstance();
      expect(dataOf(app), beforeData);
      BackupIO.pickFile = () async =>
          (name: 'tiyn_2026-11-14.json', bytes: bytes);

      await t.tap(find.text('Восстановить из копии'));
      await t.pumpAndSettle();
      expect(find.text('Восстановить копию?'), findsOneWidget);
      expect(find.text('tiyn_2026-11-14.json'), findsOneWidget);
      expect(find.text('Записей'), findsOneWidget);
      expect(find.text('Баланс'), findsOneWidget);
      expect(find.text('Копилка'), findsOneWidget);
      expect(find.text('−111 ₸'), findsOneWidget); // 0 − 111
      expect(find.text('5 ₸'), findsOneWidget);
      expect(
        find.text(
          'Текущие данные заменятся. Перед заменой\nмы сохраним их автоматически.',
        ),
        findsOneWidget,
      );

      // "Cancel": nothing changes
      await t.tap(find.text('Отмена'));
      await t.pumpAndSettle();
      expect(dataOf(app), beforeData);

      await t.tap(find.text('Восстановить из копии'));
      await t.pumpAndSettle();
      await t.tap(find.text('Заменить'));
      await t.pumpAndSettle();
      // back on home, snackbar
      expect(find.text('Настройки'), findsNothing);
      expect(find.text('Данные восстановлены'), findsOneWidget);
      expect(find.text('Отменить'), findsOneWidget);
      expect(dataOf(app)['piggyStart'], 5);
      expect((dataOf(app)['transactions'] as List).length, 1);
      expect(Reminder.settings.value, (false, 8, 5));

      await t.tap(find.text('Отменить'));
      await t.pumpAndSettle();
      expect(dataOf(app), beforeData);
      expect(Reminder.settings.value, (true, 21, 30));
      expect(find.text('Прежние данные возвращены'), findsOneWidget);
    });
  });
}

final _origSave = BackupIO.saveFile;
final _origPick = BackupIO.pickFile;

/// SharedPreferences where writing one key fails.
class _FailingPrefs implements SharedPreferences {
  final SharedPreferences _p;
  final String failKey;
  _FailingPrefs(this._p, this.failKey);

  @override
  Future<bool> setString(String key, String value) async =>
      key == failKey ? false : _p.setString(key, value);

  @override
  dynamic noSuchMethod(Invocation i) =>
      Function.apply(_forward(i), i.positionalArguments, i.namedArguments);

  Function _forward(Invocation i) => switch (i.memberName) {
    #getString => _p.getString,
    #getInt => _p.getInt,
    #getBool => _p.getBool,
    #getKeys => _p.getKeys,
    #setInt => _p.setInt,
    #setBool => _p.setBool,
    #remove => _p.remove,
    #get => _p.get,
    _ => throw UnimplementedError('${i.memberName}'),
  };
}
