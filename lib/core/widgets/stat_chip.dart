import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small comic-style pill showing a leading emoji/icon and a value, matching
/// [CoinPill]'s container styling. Used for the hub and Number Quest streak
/// chips so they share one look.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.leading,
    required this.value,
    this.fontSize = 18,
  });

  final String leading;
  final String value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.ink, width: 2.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.comicShadow(offset: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(leading, style: TextStyle(fontSize: fontSize)),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
