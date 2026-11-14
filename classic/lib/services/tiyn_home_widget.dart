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
    final accent = appTheme.accent;
    final onHand = w.onHand, free = w.free, hasPlans = w.plans.isNotEmpty;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
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

/// The widget card itself. Independent of the app theme: drawn separately.
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
    this.accent = AccentId.red,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? const Color(0xFFF2F2F2) : const Color(0xFF111113);
    final bg = dark ? const Color(0xFF0B0B0C) : const Color(0xFFF3F1F0);
    final muted = fg.withValues(alpha: 0.5);
    final text = formatMoney(onHand);
    final digits = text.substring(0, text.length - 2);
    final short = free < 0;
    final dot = accent.forBrightness(dark ? Brightness.dark : Brightness.light);
    return Container(
      width: TiynHomeWidget.size.width,
      height: TiynHomeWidget.size.height,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (dark ? Colors.white : Colors.black).withValues(
            alpha: dark ? 0.08 : 0.06,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'На руках',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: muted,
                ),
              ),
              const Spacer(),
              Text(
                'Tiyn',
                style: TextStyle(
                  fontFamily: 'Doto',
                  fontVariations: kDotoVariations,
                  fontSize: 18,
                  height: 1,
                  color: fg,
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: digits,
                      style: TextStyle(
                        fontFamily: 'Doto',
                        fontVariations: kDotoVariations,
                        fontSize: 58,
                        height: 1.05,
                        wordSpacing: -58 * 0.28,
                        color: fg,
                      ),
                    ),
                    TextSpan(
                      text: ' ₸',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: fg.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  !hasPlans
                      ? 'Обновлено ${_hm(DateTime.now())}'
                      : short
                      ? 'Не хватает на планы ${formatMoney(-free)}'
                      : 'Свободно ${formatMoney(free)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: short
                        ? (dark ? AccentId.red.dark : const Color(0xFFB3151C))
                        : muted,
                  ),
                ),
              ),
              // On Android a separate tap target sits on top of the "+".
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
