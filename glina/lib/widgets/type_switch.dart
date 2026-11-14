import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';

/// Looks 34 dp tall, the tap target is 48 dp.
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
    final g = context.g;
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
            style: golos(
              14,
              value == isRight ? 700 : 500,
              color: value == isRight ? g.ink : g.ink2,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 34,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: g.ink.withValues(alpha: g.dark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: AnimatedAlign(
                duration: kFast,
                curve: Curves.easeOutCubic,
                alignment: isRight
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: g.surf,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: g.dark
                            ? Colors.black.withValues(alpha: 0.45)
                            : g.ink.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
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
