import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';

class SettingsSectionHead extends StatelessWidget {
  final String text;
  const SettingsSectionHead(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
    child: SizedBox(
      height: 16,
      child: Transform.translate(
        offset: const Offset(0, -5),
        child: Text(text, style: golos(13, 700, color: context.g.ink2)),
      ),
    ),
  );
}

class SettingsCard extends StatelessWidget {
  final Widget child;
  const SettingsCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Material(
    color: context.g.surf,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class SettingsRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Glina.tint(g.accent, g.surf),
                ),
                child: icon,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: golos(15, 600, color: g.ink)),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
