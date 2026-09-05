import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A compact hero-level display: "LV 3" badge plus an XP progress bar.
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.level,
    required this.progress,
    this.width = 140,
  });

  final int level;
  final double progress; // 0..1
  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            border: Border.all(color: AppTheme.ink, width: 2.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'LV $level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white,
              color: AppTheme.accent,
            ),
          ),
        ),
      ],
    );
  }
}
