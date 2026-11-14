import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_app/app.dart';

void main() {
  Future<void> open(WidgetTester tester, Map<String, Object> prefs) async {
    tester.view.physicalSize = const Size(393, 873) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(const TiynApp());
    await tester.pumpAndSettle();
  }

  const income =
      '[{"id":"1","amount":10000,"kind":"income","category":"Стипендия","note":"","date":"2026-10-01T10:00:00.000"}]';

  testWidgets('Сумма 0: ничего не создаётся', (tester) async {
    await open(tester, {'transactions': income});
    await tester.tap(find.text('Кафе').first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Добавлено'), findsNothing);
    expect(find.text('Отложить'), findsNothing);
  });

  testWidgets('Трата одним тапом и отмена', (tester) async {
    await open(tester, {'transactions': income});
    await tester.enterText(find.byType(TextField).first, '900');
    await tester.pump();
    await tester.tap(find.text('Кафе').first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Добавлено · Кафе'), findsOneWidget);
    expect(find.text('9 100 ₸'), findsWidgets); // 10 000 − 900
    await tester.tap(find.text('Отменить'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('10 000 ₸'), findsWidgets);
  });

  testWidgets('Отложить в копилку и отмена; больше, чем на руках, нельзя', (
    tester,
  ) async {
    await open(tester, {'transactions': income, 'piggy_start': 19000});
    expect(find.text('19 000 ₸'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '3000');
    await tester.pump();
    await tester.tap(find.text('Отложить'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Отложено'), findsOneWidget);
    expect(find.text('22 000 ₸'), findsOneWidget);
    expect(find.text('7 000 ₸'), findsWidgets);
    await tester.tap(find.text('Отменить'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('19 000 ₸'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '50000');
    await tester.pump();
    await tester.tap(find.text('Отложить'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('На руках только'), findsOneWidget);
    expect(find.text('19 000 ₸'), findsNothing); // поле всё ещё с суммой
  });

  testWidgets('Строка «Копилка» открывает экран копилки', (tester) async {
    await open(tester, {'transactions': income, 'piggy_start': 19000});
    await tester.tap(find.text('Копилка').first);
    await tester.pumpAndSettle();
    expect(find.text('Положить'), findsWidgets);
  });
}
