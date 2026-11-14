import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

class GroupTitle extends StatelessWidget {
  final String text;
  final int? sum;
  const GroupTitle(this.text, {super.key, this.sum});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final ink = dark ? const Color(0xFFF2F2F2) : const Color(0xFF111111);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: ink.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (sum != null)
            Text(
              formatMoney(-sum!),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF8E8E93),
              ),
            ),
        ],
      ),
    );
  }
}
