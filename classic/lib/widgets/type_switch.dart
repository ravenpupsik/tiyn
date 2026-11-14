import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/theme/tokens.dart';

class TypeSwitch extends StatelessWidget {
  final String left, right;
  final bool isRight;
  final ValueChanged<bool> onChanged;
  const TypeSwitch({
    super.key,
    required this.left,
    required this.right,
    required this.isRight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    Widget label(String text, bool value) => Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (value != isRight) {
            HapticFeedback.selectionClick();
            onChanged(value);
          }
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: kFast,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: value == isRight
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.5),
            ),
            child: Text(text),
          ),
        ),
      ),
    );
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: dark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: kFast,
            curve: Curves.easeOutCubic,
            alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    if (!dark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Row(children: [label(left, false), label(right, true)]),
        ],
      ),
    );
  }
}
