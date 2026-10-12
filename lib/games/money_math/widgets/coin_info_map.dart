import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../models/money_question.dart';
import 'coin_chip.dart';

/// The Coin Info Map (legend): a friendly sheet listing EACH coin of the
/// current currency with its minted [CoinChip] visual, localized name, and
/// value. This is the key clarity feature for ages 6-9 — one tap from the home
/// and game screens explains every coin.
class CoinInfoMap extends StatelessWidget {
  const CoinInfoMap({super.key, required this.currency});

  final Currency currency;

  /// Opens the legend as a modal bottom sheet.
  static Future<void> show(BuildContext context, Currency currency) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CoinInfoMap(currency: currency),
    );
  }

  String _coinName(AppStrings s, Coin coin) => currency == Currency.ils
      ? s.ilsCoinName(coin.cents)
      : s.usdCoinName(coin.cents);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final coins = Coin.forCurrency(currency);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ComicPanel(
          color: AppTheme.paper,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Cap height so the sheet never fills the whole screen; the coin
              // list scrolls if it is tall. A fixed cap keeps us off
              // MediaQuery-based sizing (see steering).
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '💰 ${l.coinInfoTitle}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final coin in coins) ...[
                              _CoinRow(
                                coin: coin,
                                name: _coinName(l, coin),
                                value: currency.format(coin.cents),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ComicButton(
                      label: l.coinInfoClose,
                      color: AppTheme.success,
                      expand: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CoinRow extends StatelessWidget {
  const _CoinRow({
    required this.coin,
    required this.name,
    required this.value,
  });

  final Coin coin;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: AppTheme.comicBorder,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.comicShadow(offset: 3),
      ),
      child: Row(
        children: [
          CoinChip(coin: coin, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ),
          // Value reads left-to-right even in Hebrew.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
