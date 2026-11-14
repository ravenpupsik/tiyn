import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';

class SolidCard extends StatelessWidget {
  final List<Widget> children;
  const SolidCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: g.surf,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                color: context.g.line,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
