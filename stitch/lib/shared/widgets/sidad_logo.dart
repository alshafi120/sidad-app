import 'package:flutter/material.dart';

class SidadLogo extends StatelessWidget {
  final double size;
  const SidadLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SidadLogoPainter(),
      ),
    );
  }
}

class SidadLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00BFA5), Color(0xFF005045)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // A stylized 'S' shaped logo built with three overlapping polygons
    final double w = size.width;
    final double h = size.height;

    // Top block
    final topPath = Path()
      ..moveTo(w * 0.25, h * 0.1)
      ..lineTo(w * 0.75, h * 0.1)
      ..arcToPoint(Offset(w * 0.95, h * 0.3), radius: Radius.circular(w * 0.2))
      ..lineTo(w * 0.95, h * 0.45)
      ..lineTo(w * 0.7, h * 0.45)
      ..arcToPoint(Offset(w * 0.7, h * 0.3), radius: Radius.circular(w * 0.1), clockwise: false)
      ..lineTo(w * 0.25, h * 0.3)
      ..close();

    // Middle block
    final midPath = Path()
      ..moveTo(w * 0.35, h * 0.4)
      ..lineTo(w * 0.85, h * 0.4)
      ..lineTo(w * 0.85, h * 0.6)
      ..lineTo(w * 0.35, h * 0.6)
      ..close();

    // Bottom block
    final bottomPath = Path()
      ..moveTo(w * 0.75, h * 0.9)
      ..lineTo(w * 0.25, h * 0.9)
      ..arcToPoint(Offset(w * 0.05, h * 0.7), radius: Radius.circular(w * 0.2))
      ..lineTo(w * 0.05, h * 0.55)
      ..lineTo(w * 0.3, h * 0.55)
      ..arcToPoint(Offset(w * 0.3, h * 0.7), radius: Radius.circular(w * 0.1), clockwise: false)
      ..lineTo(w * 0.75, h * 0.7)
      ..close();

    canvas.drawPath(topPath, paint);
    canvas.drawPath(midPath, paint);
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
