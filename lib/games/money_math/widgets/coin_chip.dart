import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/money_question.dart';

/// A minted-coin chip: a bordered circle in a coin-metal color with its value
/// PRINTED ON IT (e.g. "5¢", "₪1", "10"). Replaces the old abstract
/// colored-circle emoji so denominations are legible for ages 6-9.
///
/// No image assets — the chip is drawn with a [Container]/[Text] in the comic
/// style (thick ink border, hard offset shadow). The value label is an LTR
/// island so numerals/symbols read naturally inside Hebrew (RTL) screens.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coin, this.size = 54});

  final Coin coin;

  /// Diameter in logical pixels. Default is a comfortable, legible tap size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final metal = coin.color ?? const Color(0xFFE0CB8A);
    // A soft inner ring gives the chip a minted feel without any assets.
    final ring = Color.lerp(metal, Colors.white, 0.35)!;
    final fontSize = (size * 0.34).clamp(12.0, 22.0);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [ring, metal],
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
        ),
        border: Border.all(color: AppTheme.ink, width: 3),
        boxShadow: AppTheme.comicShadow(offset: 3),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              coin.chipLabel,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapping row of [CoinChip]s for a pile of coins. Uses the available width
/// (via its parent's constraints) and wraps so several coins never overflow the
/// 430px phone frame. Kept LTR so the chips read left-to-right in Hebrew too.
class CoinChipRow extends StatelessWidget {
  const CoinChipRow({super.key, required this.coins, this.chipSize = 50});

  final List<Coin> coins;
  final double chipSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale chips down a touch for big piles so a row of several always
        // fits within the available width without overflow.
        final perRow = (constraints.maxWidth / (chipSize + 8)).floor();
        final needed = coins.length;
        var size = chipSize;
        if (perRow > 0 && needed > perRow * 2) {
          size = (chipSize * 0.8).clamp(30.0, chipSize);
        }
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final c in coins) CoinChip(coin: c, size: size),
            ],
          ),
        );
      },
    );
  }
}
