import 'package:flutter/material.dart';

class CatIcon extends StatelessWidget {
  final String icon;
  final Color color;
  final double size;
  const CatIcon(this.icon, {super.key, required this.color, this.size = 20});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _CatIconPainter(icon, color)),
  );
}

class _CatIconPainter extends CustomPainter {
  final String icon;
  final Color color;
  const _CatIconPainter(this.icon, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    void l(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), line);
    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    switch (icon) {
      case 'bowl':
        l(4, 12, 20, 12);
        canvas.drawPath(
          Path()
            ..moveTo(5, 12)
            ..quadraticBezierTo(5.5, 19, 12, 19)
            ..quadraticBezierTo(18.5, 19, 19, 12),
          line,
        );
        l(10.5, 4.5, 11, 9);
        l(13.5, 4.5, 13, 9);
      case 'cup':
        canvas.drawPath(
          Path()
            ..moveTo(5, 10)
            ..lineTo(16, 10)
            ..lineTo(16, 13)
            ..quadraticBezierTo(16, 17, 12, 17)
            ..lineTo(9, 17)
            ..quadraticBezierTo(5, 17, 5, 13)
            ..close(),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(16, 11.5)
            ..lineTo(17.5, 11.5)
            ..arcToPoint(
              const Offset(17.5, 15.5),
              radius: const Radius.circular(2),
            )
            ..lineTo(15.8, 15.5),
          line,
        );
        l(3.5, 20, 17.5, 20);
        l(9, 4.5, 9, 7);
        l(12, 4.5, 12, 7);
      case 'bus':
        canvas.drawRRect(rr(4, 4.5, 16, 13, 3), line);
        l(4, 11, 20, 11);
        canvas.drawCircle(const Offset(8, 14.2), 1, fill);
        canvas.drawCircle(const Offset(16, 14.2), 1, fill);
        l(7.5, 17.5, 7.5, 20);
        l(16.5, 17.5, 16.5, 20);
      case 'book':
        canvas.drawRRect(rr(5.5, 3.5, 13, 17, 2.5), line);
        l(9.5, 3.5, 9.5, 20.5);
        l(12.5, 8, 16, 8);
        l(12.5, 11.5, 16, 11.5);
        l(12.5, 15, 14.5, 15);
      case 'play':
        canvas.drawRRect(rr(3, 5.5, 18, 13, 3.5), line);
        canvas.drawPath(
          Path()
            ..moveTo(10.2, 9.4)
            ..lineTo(14.6, 12)
            ..lineTo(10.2, 14.6)
            ..close(),
          line,
        );
      case 'bag':
        canvas.drawPath(
          Path()
            ..moveTo(6, 9)
            ..lineTo(18, 9)
            ..lineTo(19, 19.5)
            ..lineTo(5, 19.5)
            ..close(),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9, 9)
            ..lineTo(9, 7)
            ..arcToPoint(const Offset(15, 7), radius: const Radius.circular(3))
            ..lineTo(15, 9),
          line,
        );
      case 'wallet':
        canvas.drawRRect(rr(3, 7, 18, 12.5, 3), line);
        l(6, 7, 15.5, 4.5);
        canvas.drawRRect(rr(14, 11.5, 7, 4.5, 2.2), line);
        canvas.drawCircle(const Offset(16.8, 13.75), 0.8, fill);
      case 'cash':
        canvas.drawRRect(rr(3, 6.5, 18, 11, 2.5), line);
        canvas.drawCircle(const Offset(12, 12), 2.5, line);
        canvas.drawCircle(const Offset(6.5, 12), 0.7, fill);
        canvas.drawCircle(const Offset(17.5, 12), 0.7, fill);
      case 'case':
        canvas.drawRRect(rr(3.5, 8, 17, 11.5, 2.5), line);
        canvas.drawPath(
          Path()
            ..moveTo(9, 8)
            ..lineTo(9, 6.5)
            ..lineTo(15, 6.5)
            ..lineTo(15, 8),
          line,
        );
        l(3.5, 13, 20.5, 13);
      case 'gift':
        canvas.drawRRect(rr(4.5, 10, 15, 10, 1.5), line);
        canvas.drawRRect(rr(3.5, 7, 17, 3.5, 1.2), line);
        l(12, 7, 12, 20);
        canvas.drawPath(
          Path()
            ..moveTo(12, 7)
            ..cubicTo(10, 3.5, 7, 4.5, 8.5, 7),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12, 7)
            ..cubicTo(14, 3.5, 17, 4.5, 15.5, 7),
          line,
        );
      case 'swap':
        l(8, 5, 8, 18);
        l(5, 15, 8, 18);
        l(11, 15, 8, 18);
        l(16, 19, 16, 6);
        l(13, 9, 16, 6);
        l(19, 9, 16, 6);
      case 'piggy':
        canvas.drawPath(
          Path()
            ..moveTo(5, 12.5)
            ..cubicTo(5, 8.5, 8.5, 7, 12, 7)
            ..cubicTo(15.5, 7, 19, 8.8, 19, 12.5)
            ..cubicTo(19, 15, 17.8, 16.4, 16.5, 17.2)
            ..lineTo(16.5, 19.5)
            ..lineTo(14, 19.5)
            ..lineTo(14, 18.3)
            ..lineTo(10, 18.3)
            ..lineTo(10, 19.5)
            ..lineTo(7.5, 19.5)
            ..lineTo(7.5, 17.2)
            ..cubicTo(6, 16.2, 5, 14.8, 5, 12.5),
          line,
        );
        l(11, 4.5, 14, 4.5);
        canvas.drawCircle(const Offset(15.3, 11.2), 0.8, fill);
        l(3, 11, 5, 12);
      default:
        canvas.drawCircle(const Offset(6, 12), 1.7, fill);
        canvas.drawCircle(const Offset(12, 12), 1.7, fill);
        canvas.drawCircle(const Offset(18, 12), 1.7, fill);
    }
  }

  @override
  bool shouldRepaint(_CatIconPainter old) =>
      old.icon != icon || old.color != color;
}
