import 'package:flutter/material.dart';

/// Small dashed rule used under the active tab label — a recurring "Warm
/// Journal" motif (also used under the hero card's piece title).
class DashedUnderline extends StatelessWidget {
  const DashedUnderline({
    super.key,
    required this.color,
    this.width = 28,
    this.strokeWidth = 2,
  });

  final Color color;
  final double width;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, strokeWidth),
      painter: _DashedLinePainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4.0;
    const gapWidth = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
