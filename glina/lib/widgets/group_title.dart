import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

class GroupTitle extends StatelessWidget {
  final String text;
  final int? sum;
  final double top;
  const GroupTitle(this.text, {super.key, this.sum, this.top = 20});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: golos(13, 700, color: g.ink, height: 1.2)),
          ),
          if (sum != null)
            Text(
              formatMoney(-sum!),
              style: golos(13, 600, color: g.ink2, height: 1.2),
            ),
        ],
      ),
    );
  }
}
