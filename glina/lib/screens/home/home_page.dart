import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/wallet.dart';
import 'package:money_app/screens/editor/editor_actions.dart';
import 'package:money_app/screens/home/floating_bar.dart';
import 'package:money_app/screens/home/home_feed.dart';
import 'package:money_app/screens/piggy/piggy_page.dart';
import 'package:money_app/screens/plans/plans_page.dart';
import 'package:money_app/screens/settings/backup_snacks.dart';
import 'package:money_app/screens/settings/settings_page.dart';
import 'package:money_app/screens/stats/stats_page.dart';
import 'package:money_app/services/reminder.dart';
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/backdrop.dart';
import 'package:money_app/widgets/fade_route.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _wallet = Wallet();
  int _tab = 0;
  int _statsVisit = 0;

  void _goTab(int i) {
    if (_tab == i) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab = i;
      if (i == 1) _statsVisit++;
    });
  }

  @override
  void initState() {
    super.initState();
    _wallet.load();
    Reminder.openAdd.addListener(_openAddFromNotification);
    if (Reminder.launchedFromTap) {
      Reminder.launchedFromTap = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openAddFromNotification(),
      );
    }
  }

  @override
  void dispose() {
    Reminder.openAdd.removeListener(_openAddFromNotification);
    _wallet.dispose();
    super.dispose();
  }

  void _openAddFromNotification() {
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => _tab = 0);
    openTxnEditor(context, _wallet);
  }

  Future<void> _openSettings() async {
    final restored = await Navigator.of(context)
        .push<bool>(fadeRoute<bool>(SettingsPage(wallet: _wallet)));
    if (restored == true && mounted) {
      showRestoredSnack(context, _wallet);
    }
  }

  void _openPiggy() =>
      Navigator.of(context).push(fadeRoute(PiggyPage(wallet: _wallet)));

  @override
  Widget build(BuildContext context) {
    // Android Back returns to the home tab first.
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayFor(context),
        child: Scaffold(
          backgroundColor: context.g.bg,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              const Positioned.fill(child: Backdrop()),
              IndexedStack(
                index: _tab,
                children: [
                  ListenableBuilder(
                    listenable: _wallet,
                    builder: (context, _) => HomeFeed(
                      wallet: _wallet,
                      onOpenPiggy: _openPiggy,
                      onOpenSettings: _openSettings,
                      onOpenStats: () => _goTab(1),
                      onOpenPlans: () => _goTab(2),
                    ),
                  ),
                  // A new key on every tab entry makes Stats always open on
                  // Month.
                  StatsPage(
                    key: ValueKey(_statsVisit),
                    wallet: _wallet,
                    inTab: true,
                  ),
                  PlansPage(wallet: _wallet, inTab: true),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
                child: FloatingBar(
                  index: _tab,
                  onSelect: _goTab,
                  onAdd: () => openTxnEditor(context, _wallet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 5) return 'Доброй ночи';
  if (h < 12) return 'Доброе утро';
  if (h < 18) return 'Добрый день';
  return 'Добрый вечер';
}
