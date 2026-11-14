import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/frosted_glass.dart';
import 'package:money_app/widgets/pressable.dart';

class SettingsSectionHead extends StatelessWidget {
  final String text;
  const SettingsSectionHead(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: mutedText(context),
      ),
    ),
  );
}

class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final divider = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.08);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF1C1C1F).withValues(alpha: 0.62)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 66, color: divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: kAmberGradient,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSheet extends StatelessWidget {
  final List<Widget> children;
  const SettingsSheet({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SettingsSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  final String text;
  const SheetTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class SheetNote extends StatelessWidget {
  final String text;
  const SheetNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: mutedText(context), fontSize: 13),
  );
}

class SheetPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SheetPrimaryButton(this.label, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onPrimary,
          ),
        ),
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: mutedText(context),
            ),
          ),
        ),
      ),
    ),
  );
}

class SettingsSheetFrame extends StatelessWidget {
  final Widget child;
  const SettingsSheetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => FrostedGlass(
    blur: 20,
    fill: 0.82,
    radius: const BorderRadius.vertical(top: Radius.circular(32)),
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
    child: SafeArea(top: false, child: SingleChildScrollView(child: child)),
  );
}
