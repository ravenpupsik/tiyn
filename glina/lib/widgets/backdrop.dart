import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';

class Backdrop extends StatelessWidget {
  const Backdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return RepaintBoundary(
      child: CustomPaint(size: Size.infinite, painter: _BackdropPainter(g)),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final Glina g;
  const _BackdropPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = g.bg);
    void blob(Offset c, double r, Color color, double alpha) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    final w = size.width, h = size.height;
    if (g.dark) {
      blob(Offset(w * 0.05, h * 0.06), w * 0.8, const Color(0xFF6B3A2A), 0.28);
      blob(Offset(w * 0.98, h * 0.10), w * 0.7, const Color(0xFF2F4A3C), 0.22);
      blob(Offset(w * 0.5, h * 0.92), w * 0.8, const Color(0xFF4A3426), 0.18);
    } else {
      blob(Offset(w * 0.05, h * 0.06), w * 0.8, const Color(0xFFF2C3AE), 0.45);
      blob(Offset(w * 0.98, h * 0.10), w * 0.7, const Color(0xFFCBD8C8), 0.45);
      blob(Offset(w * 0.5, h * 0.92), w * 0.8, const Color(0xFFE9D3C2), 0.45);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.g != g;
}
