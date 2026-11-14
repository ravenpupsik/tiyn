import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'package:money_app/data/wallet.dart';
import 'package:money_app/theme/app_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

/// 4×2 "На руках" widget. Android widgets can't use app fonts, so the app
/// renders the card as an image (dark and light) and the widget only shows the
/// right one. Redrawn after every change of entries.
class TiynHomeWidget {
  static bool platformEnabled = false;
  static Timer? _debounce;
  static const size = Size(360, 170);
  static const _provider = 'com.moneycash.money_app.BalanceWidgetProvider';

  static void update(Wallet w) {
    if (!platformEnabled) return;
    final onHand = w.onHand, free = w.free, hasPlans = w.plans.isNotEmpty;
    final mode = appTheme.mode, accent = appTheme.accent;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        // Images are drawn in the chosen accent (light and dark); the theme
        // mode decides which one is shown: "system" follows the phone, "light"
        // and "dark" ignore it.
        await HomeWidget.saveWidgetData<String>('theme_mode', mode.name);
        await HomeWidget.saveWidgetData<String>('accent', accent.id);
        for (final dark in [true, false]) {
          await HomeWidget.renderFlutterWidget(
            BalanceWidgetCard(
              onHand: onHand,
              free: free,
              hasPlans: hasPlans,
              dark: dark,
              accent: accent,
            ),
            key: dark ? 'balance_dark' : 'balance_light',
            logicalSize: size,
            pixelRatio: 3,
          );
        }
        await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
      } catch (_) {
        // The widget may not be on screen: not an error.
      }
    });
  }
}

/// The widget card itself. Independent of the app theme: drawn separately in
/// light and dark variants with the chosen accent.
class BalanceWidgetCard extends StatelessWidget {
  final int onHand;
  final int free;
  final bool hasPlans;
  final bool dark;
  final AccentId accent;
  const BalanceWidgetCard({
    super.key,
    required this.onHand,
    required this.free,
    required this.hasPlans,
    required this.dark,
    this.accent = AccentId.clay,
  });

  @override
  Widget build(BuildContext context) {
    final g = Glina.palette(dark ? Brightness.dark : Brightness.light, accent);
    final short = free < 0;
    final bottomText = !hasPlans
        ? 'Обновлено ${_hm(DateTime.now())}'
        : short
        ? 'Не хватает на планы ${formatMoney(-free)}'
        : 'Свободно  ${formatMoney(free)}';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: TiynHomeWidget.size.width,
        height: TiynHomeWidget.size.height,
        decoration: BoxDecoration(
          color: g.surf,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 17,
              child: Text(
                'На руках',
                style: golos(13, 600, color: g.ink2, height: 1.25),
              ),
            ),
            Positioned(
              right: 20,
              top: 14,
              child: Text(
                'Tiyn',
                style: nunito(14, 800, color: g.ink, height: 1.25),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 58,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMoney(onHand),
                  style: literata(36, color: g.ink, height: 1.2),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 76,
              bottom: 26,
              child: Text(
                bottomText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: golos(
                  14,
                  600,
                  color: short && hasPlans ? g.accent : g.ink2,
                  height: 1.25,
                ),
              ),
            ),
            // On Android a separate tap target sits on top of the "+".
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: g.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, color: g.onAccent, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
