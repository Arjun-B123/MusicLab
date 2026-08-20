import 'package:flutter/material.dart';

/// A full moon with a handful of craters — used in place of the plain
/// Material moon icon for the dark-mode toggle, to actually look like a
/// moon rather than a generic crescent glyph.
class MoonIcon extends StatelessWidget {
  const MoonIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MoonPainter(color: color)),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({required this.color});

  final Color color;

  // Crater positions/radii as fractions of the moon's radius, hand-placed
  // to read as a moon at small icon sizes rather than a random speckle.
  static const _craters = [
    (dx: -0.28, dy: -0.22, r: 0.20),
    (dx: 0.20, dy: -0.35, r: 0.12),
    (dx: 0.30, dy: 0.15, r: 0.16),
    (dx: -0.10, dy: 0.30, r: 0.10),
    (dx: -0.35, dy: 0.15, r: 0.08),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final body = Paint()..color = color;
    canvas.drawCircle(center, radius, body);

    // Craters darken the moon slightly rather than punching holes, so
    // "full moon" reads at a glance even at 16-18px.
    final craterPaint = Paint()..color = Colors.black.withValues(alpha: 0.16);
    for (final c in _craters) {
      final craterCenter = Offset(
        center.dx + c.dx * radius * 2,
        center.dy + c.dy * radius * 2,
      );
      canvas.drawCircle(craterCenter, c.r * radius * 2, craterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      oldDelegate.color != color;
}
