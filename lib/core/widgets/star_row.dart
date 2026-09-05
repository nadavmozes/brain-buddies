import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Displays [earned] filled stars out of [total].
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.earned,
    this.total = 3,
    this.size = 28,
  });

  final int earned;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final filled = i < earned;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? AppTheme.accent : Colors.grey.shade400,
            size: size,
            shadows: const [
              Shadow(color: AppTheme.ink, offset: Offset(1.5, 1.5)),
            ],
          ),
        );
      }),
    );
  }
}
