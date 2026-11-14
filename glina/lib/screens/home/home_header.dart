import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/screens/home/home_page.dart';
import 'package:money_app/screens/intro/intro_gate.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

class HomeHeader extends StatelessWidget {
  final DateTime now;
  final VoidCallback onSettings;
  const HomeHeader({super.key, required this.now, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    greetingFor(now),
                    style: golos(13, 600, color: g.ink2, height: 1.2),
                  ),
                ),
                Positioned(
                  right: -10,
                  top: -12,
                  child: _HeaderIcon(
                    icon: Icons.settings_outlined,
                    label: 'Настройки',
                    size: 24,
                    onTap: onSettings,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Hidden while the intro runs: the intro word flies into its
              // place. Same style (Nunito 26/800) so it does not jump.
              ValueListenableBuilder<bool>(
                valueListenable: introRunning,
                builder: (_, running, child) =>
                    Opacity(opacity: running ? 0 : 1, child: child),
                child: Text('Tiyn', key: logoKey, style: logoStyle(g.ink)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  formatShortDate(now, now: now),
                  style: golos(13, 600, color: g.ink2, height: 1.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  const _HeaderIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 21,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: size, color: g.ink2),
        ),
      ),
    );
  }
}
