import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small comic-style pill showing a coin icon and an amount.
class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.amount, this.fontSize = 18});

  final int amount;
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
          Text('🪙', style: TextStyle(fontSize: fontSize)),
          const SizedBox(width: 6),
          Text(
            '$amount',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
