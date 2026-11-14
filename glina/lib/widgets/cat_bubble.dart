import 'package:flutter/material.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/theme/cat_icons.dart';
import 'package:money_app/theme/tokens.dart';

class CatBubble extends StatelessWidget {
  final Category cat;
  final double diameter;
  final double? iconSize;
  const CatBubble(this.cat, {super.key, this.diameter = 30, this.iconSize});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final color = cat.forDark(g.dark);
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Glina.tint(color, g.surf),
        shape: BoxShape.circle,
      ),
      child: CatIcon(cat.icon, color: color, size: iconSize ?? diameter * 0.55),
    );
  }
}
