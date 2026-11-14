import 'package:flutter/material.dart';

class DonutPainter extends CustomPainter {
  final List<(Color, int)> parts;
  final double progress;
  final Color track;
  const DonutPainter({
    required this.parts,
    required this.progress,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 24.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    canvas.drawArc(
      rect,
      0,
      6.2832,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final total = parts.fold<int>(0, (s, p) => s + p.$2);
    if (total == 0) return;

    const full = 6.2832;
    final gap = parts.length > 1 ? 0.035 : 0.0;
    final drawn = full * progress;
    var start = -full / 4;
    var used = 0.0;
    for (final (color, value) in parts) {
      final sweep = full * value / total;
      final visible = (drawn - used).clamp(0.0, sweep);
      final arc = visible - gap;
      if (arc > 0) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          arc,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.butt
            ..color = color,
        );
      }
      start += sweep;
      used += sweep;
    }
  }

  @override
  bool shouldRepaint(DonutPainter old) =>
      old.progress != progress || old.parts != parts || old.track != track;
}
