import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'coin_pill.dart';

/// The top-right HUD shared by the secondary game homes: a star icon with the
/// total star count, followed by a [CoinPill] of the shared coin balance.
class StarCoinHud extends StatelessWidget {
  const StarCoinHud({super.key, required this.stars, required this.coins});

  final int stars;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppTheme.accent, size: 22),
        Text(' $stars ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        CoinPill(amount: coins),
      ],
    );
  }
}
