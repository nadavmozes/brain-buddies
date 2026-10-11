import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// The "All Games" back link shared by the secondary game homes. Taps call
/// [Navigator.maybePop], returning to the hub.
///
/// The [Row] follows [Directionality], so the icon/label order mirrors in
/// Hebrew (RTL) automatically; the arrow glyph is flipped in RTL so it still
/// points toward the start (the direction "back" travels).
class AllGamesBackButton extends StatelessWidget {
  const AllGamesBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.flip(
            flipX: rtl,
            child: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          ),
          Text(context.l10n.allGames,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.ink)),
        ],
      ),
    );
  }
}
