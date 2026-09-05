import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/clock_time.dart';

/// Draws an analog clock face showing [time]. No image assets.
class ClockFace extends StatelessWidget {
  const ClockFace({super.key, required this.time, this.size = 160});

  final ClockTime time;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ClockPainter(time)),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.time);

  final ClockTime time;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final face = Paint()..color = Colors.white;
    final outline = Paint()
      ..color = AppTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(c, r - 3, face);
    canvas.drawCircle(c, r - 3, outline);

    // Hour ticks + numbers.
    final tickPaint = Paint()
      ..color = AppTheme.ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 12; i++) {
      final angle = (i / 12) * 2 * pi - pi / 2;
      final outer = Offset(c.dx + (r - 10) * cos(angle),
          c.dy + (r - 10) * sin(angle));
      final inner = Offset(c.dx + (r - 20) * cos(angle),
          c.dy + (r - 20) * sin(angle));
      canvas.drawLine(inner, outer, tickPaint);

      // Numbers
      final numPos = Offset(c.dx + (r - 34) * cos(angle),
          c.dy + (r - 34) * sin(angle));
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, numPos - Offset(tp.width / 2, tp.height / 2));
    }

    // Hand angles. The hour hand advances with the minutes.
    final minuteAngle = (time.minute / 60) * 2 * pi - pi / 2;
    final hourAngle =
        ((time.hour % 12) / 12 + time.minute / 720) * 2 * pi - pi / 2;

    // Hour hand (short, thick).
    final hourPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      c,
      Offset(c.dx + (r * 0.5) * cos(hourAngle),
          c.dy + (r * 0.5) * sin(hourAngle)),
      hourPaint,
    );

    // Minute hand (long, thinner).
    final minutePaint = Paint()
      ..color = AppTheme.danger
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      c,
      Offset(c.dx + (r * 0.72) * cos(minuteAngle),
          c.dy + (r * 0.72) * sin(minuteAngle)),
      minutePaint,
    );

    // Center pin.
    canvas.drawCircle(c, 6, Paint()..color = AppTheme.ink);
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.time != time;
}
