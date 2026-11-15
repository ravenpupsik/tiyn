import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_app/data/backup_data.dart';
import 'package:money_app/data/category.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/widgets/backdrop.dart';

String backupWith(String category) => jsonEncode({
  'app': 'tiyn',
  'version': 1,
  'data': {
    'transactions': [
      {
        'id': 'a',
        'amount': 500,
        'kind': 'expense',
        'category': category,
        'note': '',
        'date': '2026-11-10T12:00:00',
      },
    ],
    'plans': [
      {
        'id': 'p',
        'title': '',
        'amount': 100,
        'category': category,
        'due': null,
      },
    ],
    'lastCatExpense': category,
  },
});

void main() {
  test('canonicalCategory: регистр и «ё» не важны, неизвестное не трогаем', () {
    expect(canonicalCategory('ДРУГОЕ'), 'Другое');
    expect(canonicalCategory('другое'), 'Другое');
    expect(canonicalCategory('  кафе '), 'Кафе');
    expect(canonicalCategory('УЧЕБА'), 'Учёба');
    expect(canonicalCategory('Хобби '), 'Хобби');
    expect(canonicalCategory(''), '');
  });

  test('findCategory показывает каноничное имя для любого регистра', () {
    expect(findCategory('ДРУГОЕ', false).name, 'Другое');
    expect(findCategory('ЕДА', false).name, 'Еда');
    expect(findCategory('СТИПЕНДИЯ', true).name, 'Стипендия');
    expect(findCategory('что-то', true).name, 'Другое');
  });

  test('Txn.fromJson приводит категорию к каноничной', () {
    final t = Txn.fromJson({
      'id': '1',
      'amount': 10,
      'kind': 'expense',
      'category': 'ДРУГОЕ',
      'date': '2026-11-10T12:00:00',
    });
    expect(t.category, 'Другое');
  });

  test('Wallet.load приводит сохранённые категории к каноничным', () async {
    SharedPreferences.setMockInitialValues({
      'transactions': jsonEncode([
        {
          'id': '1',
          'amount': 10,
          'kind': 'expense',
          'category': 'ДРУГОЕ',
          'note': '',
          'date': '2026-11-10T12:00:00',
        },
      ]),
    });
    final w = Wallet();
    await w.load();
    expect(w.items.single.category, 'Другое');
    w.dispose();
  });

  test('восстановление из копии приводит категории к каноничным', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await Backup.restore(p, Backup.parse(backupWith('ДРУГОЕ')));
    final data = Backup.snapshot(p, DateTime(2026, 11, 15))['data'] as Map;
    expect((data['transactions'] as List).single['category'], 'Другое');
    expect((data['plans'] as List).single['category'], 'Другое');
    expect(data['lastCatExpense'], 'Другое');
  });

  testWidgets('линия под шапкой появляется только при прокрутке', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PauseBackdropOnScroll(
          child: ListView(
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 60, child: Text('$i')),
            ],
          ),
        ),
      ),
    );
    double opacity() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    expect(opacity(), 0);
    expect(backdropPaused.value, isFalse);

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(0, -150));
    await tester.pump();
    expect(opacity(), 1);
    expect(backdropPaused.value, isTrue);

    await g.up();
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    expect(backdropPaused.value, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(opacity(), 0);
  });

  test('пауза фона держится, пока её держит хоть один источник', () {
    pauseBackdrop();
    pauseBackdrop();
    resumeBackdrop();
    expect(backdropPaused.value, isTrue);
    resumeBackdrop();
    expect(backdropPaused.value, isFalse);
  });
}
