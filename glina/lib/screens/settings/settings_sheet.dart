import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/pressable.dart';

class SettingsSheet extends StatelessWidget {
  final List<Widget> children;
  const SettingsSheet({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      decoration: BoxDecoration(
        color: g.surf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 16,
                child: Center(
                  child: Container(
                    width: 52,
                    height: 4,
                    decoration: BoxDecoration(
                      color: g.ink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class SheetPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SheetPrimaryButton(this.label, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: g.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: golos(16, 700, color: g.onAccent)),
      ),
    );
  }
}

class SheetSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SheetSecondaryButton(this.label, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(label, style: golos(15, 600, color: context.g.ink2)),
        ),
      ),
    ),
  );
}
