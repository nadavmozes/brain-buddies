import 'dart:math';

import 'package:flutter/material.dart';

/// A lightweight confetti burst drawn with a CustomPainter. No packages.
///
/// Drop it into a Stack; it animates once on build and then rests.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 60});

  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Piece> _confetti;

  static const _colors = [
    Color(0xFF6C63FF),
    Color(0xFFFFD23F),
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFF4FC3F7),
    Color(0xFFEC407A),
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _confetti = List.generate(widget.pieces, (_) {
      return _Piece(
        x: rng.nextDouble(),
        startY: -rng.nextDouble() * 0.3,
        speed: 0.6 + rng.nextDouble() * 0.8,
        drift: (rng.nextDouble() - 0.5) * 0.4,
        color: _colors[rng.nextInt(_colors.length)],
        size: 6 + rng.nextDouble() * 8,
        rotation: rng.nextDouble() * pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_confetti, _controller.value),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  final double x;
  final double startY;
  final double speed;
  final double drift;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final y = (p.startY + p.speed * t) * size.height;
      if (y < -20 || y > size.height + 20) continue;
      final x = (p.x + p.drift * t) * size.width;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
