import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';

enum SettingsGlyphKind { down, up, file, bang }

class SettingsGlyph extends StatelessWidget {
  final SettingsGlyphKind kind;
  final double size;
  const SettingsGlyph(this.kind, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _GlyphPainter(kind, context.g.accentText),
  );
}

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

class _GlyphPainter extends CustomPainter {
  final SettingsGlyphKind kind;
  final Color color;
  const _GlyphPainter(this.kind, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    switch (kind) {
      case SettingsGlyphKind.down || SettingsGlyphKind.up:
        const s = 16.0;
        final up = kind == SettingsGlyphKind.up;
        final p = _stroke(color, 1.8);
        final tray = cy + s * 0.42;
        canvas.drawPath(
          Path()
            ..moveTo(cx - s * 0.5, tray - s * 0.2)
            ..lineTo(cx - s * 0.5, tray)
            ..lineTo(cx + s * 0.5, tray)
            ..lineTo(cx + s * 0.5, tray - s * 0.2),
          p,
        );
        final top = cy - s * 0.5, bot = cy + s * 0.18;
        final arrow = Path()
          ..moveTo(cx, top)
          ..lineTo(cx, bot);
        if (up) {
          arrow
            ..moveTo(cx - s * 0.28, top + s * 0.28)
            ..lineTo(cx, top)
            ..lineTo(cx + s * 0.28, top + s * 0.28);
        } else {
          arrow
            ..moveTo(cx - s * 0.28, bot - s * 0.28)
            ..lineTo(cx, bot)
            ..lineTo(cx + s * 0.28, bot - s * 0.28);
        }
        canvas.drawPath(arrow, p);
      case SettingsGlyphKind.file:
        final p = _stroke(color, 1.6);
        canvas.drawRRect(
          RRect.fromLTRBR(
            cx - 6.5,
            cy - 8.5,
            cx + 6.5,
            cy + 8.5,
            const Radius.circular(2.2),
          ),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(cx + 1.5, cy - 8.5)
            ..lineTo(cx + 6.5, cy - 3.5)
            ..moveTo(cx + 1.5, cy - 8.5)
            ..lineTo(cx + 1.5, cy - 3.5)
            ..lineTo(cx + 6.5, cy - 3.5),
          p,
        );
        final q = _stroke(color, 1.4);
        canvas.drawLine(Offset(cx - 3.2, cy + 1), Offset(cx + 3.2, cy + 1), q);
        canvas.drawLine(
          Offset(cx - 3.2, cy + 4.5),
          Offset(cx + 1.6, cy + 4.5),
          q,
        );
      case SettingsGlyphKind.bang:
        const k = 1.25;
        final f = Paint()..color = color;
        canvas.drawRRect(
          RRect.fromLTRBR(
            cx - 1.55 * k,
            cy - 9.5 * k,
            cx + 1.55 * k,
            cy + 2.4 * k,
            const Radius.circular(1.5 * k),
          ),
          f,
        );
        canvas.drawCircle(Offset(cx, cy + 7.4 * k), 1.9 * k, f);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.kind != kind || old.color != color;
}
