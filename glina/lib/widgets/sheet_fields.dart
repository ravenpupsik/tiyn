import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/spaced_digits.dart';

class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double height;
  final VoidCallback onChanged;
  final VoidCallback? onSubmitted;
  const AmountField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onSubmitted,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final ready =
            controller.text.replaceAll(' ', '').isNotEmpty &&
            controller.text.replaceAll(' ', '') != '0';
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  children: [
                    Flexible(
                      child: IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 28),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [SpacedDigits()],
                            cursorColor: g.accent,
                            cursorWidth: 2,
                            style: literata(52, color: g.ink, height: 1.1),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: literata(
                                52,
                                color: g.ink3,
                                height: 1.1,
                              ),
                            ),
                            onChanged: (_) => onChanged(),
                            onSubmitted: (_) => onSubmitted?.call(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '₸',
                      style: literata(
                        52,
                        color: ready ? g.ink : g.ink3,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Container(
                  height: focused ? 2 : 1,
                  color: focused ? g.accent : g.line,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NoteBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const NoteBox({super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: g.field,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: g.accent,
        style: golos(14, 600, color: g.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: hint,
          hintStyle: golos(14, 500, color: g.ink3),
        ),
      ),
    );
  }
}

class DateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DateChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Semantics(
      button: true,
      label: 'Дата: $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: g.field,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: g.ink2),
              const SizedBox(width: 6),
              Text(label, style: golos(13, 600, color: g.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
