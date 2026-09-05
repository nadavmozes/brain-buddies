import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/shape_kind.dart';

/// Draws a single [ShapeKind] with a bold comic outline. No image assets.
class ShapeView extends StatelessWidget {
  const ShapeView({
    super.key,
    required this.shape,
    this.size = 90,
    this.color,
  });

  final ShapeKind shape;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShapePainter(shape, color ?? shape.color),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape, this.color);

  final ShapeKind shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;

    switch (shape) {
      case ShapeKind.circle:
        canvas.drawCircle(c, r, fill);
        canvas.drawCircle(c, r, stroke);
        break;
      case ShapeKind.oval:
        final rect = Rect.fromCenter(
            center: c, width: size.width * 0.9, height: size.height * 0.6);
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, stroke);
        break;
      case ShapeKind.square:
        final rect = Rect.fromCenter(
            center: c, width: size.width * 0.8, height: size.width * 0.8);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, stroke);
        break;
      case ShapeKind.rectangle:
        final rect = Rect.fromCenter(
            center: c, width: size.width * 0.92, height: size.height * 0.6);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, stroke);
        break;
      case ShapeKind.triangle:
        _polygon(canvas, c, r, 3, fill, stroke, rotation: -pi / 2);
        break;
      case ShapeKind.pentagon:
        _polygon(canvas, c, r, 5, fill, stroke, rotation: -pi / 2);
        break;
      case ShapeKind.hexagon:
        _polygon(canvas, c, r, 6, fill, stroke, rotation: -pi / 2);
        break;
      case ShapeKind.star:
        _star(canvas, c, r, fill, stroke);
        break;
    }
  }

  void _polygon(Canvas canvas, Offset c, double r, int n, Paint fill,
      Paint stroke,
      {double rotation = 0}) {
    final path = Path();
    for (var i = 0; i < n; i++) {
      final angle = rotation + i * 2 * pi / n;
      final p = Offset(c.dx + r * cos(angle), c.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _star(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    final path = Path();
    const points = 5;
    final inner = r * 0.45;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : inner;
      final angle = -pi / 2 + i * pi / points;
      final p = Offset(c.dx + radius * cos(angle), c.dy + radius * sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape || old.color != color;
}
