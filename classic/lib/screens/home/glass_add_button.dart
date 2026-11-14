import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/theme/tokens.dart';

class GlassAddButton extends StatefulWidget {
  final VoidCallback onTap;
  const GlassAddButton({super.key, required this.onTap});

  @override
  State<GlassAddButton> createState() => _GlassAddButtonState();
}

class _GlassAddButtonState extends State<GlassAddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const size = 62.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: Duration(milliseconds: _down ? 120 : 380),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.45 : 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: CustomPaint(
                painter: _GlassOrbPainter(dark: dark),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 34,
                    color: accentOf(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassOrbPainter extends CustomPainter {
  final bool dark;
  const _GlassOrbPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c = rect.center;
    final r = size.width / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.20 : 0.80),
            Colors.white.withValues(alpha: dark ? 0.06 : 0.45),
          ],
        ).createShader(rect),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.28),
          ],
          stops: const [0, 0.72, 1],
        ).createShader(rect),
    );

    final glare = Rect.fromCenter(
      center: Offset(c.dx - r * 0.22, c.dy - r * 0.48),
      width: r * 1.1,
      height: r * 0.55,
    );
    canvas.drawOval(
      glare,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(glare)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      c,
      r - 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..shader = SweepGradient(
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.25),
          ],
          stops: const [0, 0.125, 0.5, 0.625, 1],
          transform: const GradientRotation(3.14159),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassOrbPainter old) => old.dark != dark;
}
