import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_app/app.dart';
import 'package:money_app/screens/intro/intro_gate.dart';

/// Counts how many times the home screen was created.
class _Probe extends StatefulWidget {
  static int created = 0;
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.created++;
  }

  @override
  Widget build(BuildContext context) => const Center(child: Text('home'));
}

Future<void> run(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 16; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  tearDown(() => introEnabled = false);

  testWidgets('Заставка играет секунду, главная не пересоздаётся', (
    tester,
  ) async {
    introEnabled = true;
    _Probe.created = 0;
    await tester.pumpWidget(
      const MaterialApp(home: IntroGate(child: _Probe())),
    );
    expect(introRunning.value, isTrue);
    await run(tester, 500);
    expect(introRunning.value, isTrue);
    await run(tester, 800);
    expect(introRunning.value, isFalse);
    expect(find.text('home'), findsOneWidget);
    expect(_Probe.created, 1);
  });

  testWidgets('Тап пропускает заставку, главная не пересоздаётся', (
    tester,
  ) async {
    introEnabled = true;
    _Probe.created = 0;
    await tester.pumpWidget(
      const MaterialApp(home: IntroGate(child: _Probe())),
    );
    await run(tester, 200);
    expect(introRunning.value, isTrue);
    await tester.tapAt(const Offset(100, 100));
    await tester.pump();
    expect(introRunning.value, isFalse);
    expect(find.text('home'), findsOneWidget);
    expect(_Probe.created, 1);
    await run(tester, 1200); // тикер больше ничего не ломает
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Без заставки (по уведомлению, в тестах) сразу главная', (
    tester,
  ) async {
    introEnabled = false;
    await tester.pumpWidget(
      const MaterialApp(home: IntroGate(child: _Probe())),
    );
    expect(introRunning.value, isFalse);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Отключённые анимации: заставка не играет', (tester) async {
    introEnabled = true;
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: IntroGate(child: _Probe())),
      ),
    );
    await run(tester, 100);
    expect(introRunning.value, isFalse);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('В приложении слово «Tiyn» в шапке появляется после заставки', (
    tester,
  ) async {
    introEnabled = true;
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TiynApp());
    await run(tester, 300);
    expect(introRunning.value, isTrue);
    await run(tester, 1100);
    expect(introRunning.value, isFalse);
    await tester.pumpAndSettle();
    final logo = tester.widget<Text>(find.byKey(logoKey));
    expect(logo.style!.fontSize, 26);
    expect(logo.style!.fontFamily, 'Nunito');
  });
}
