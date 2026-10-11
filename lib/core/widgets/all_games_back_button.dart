import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The "All Games" back link shared by the secondary game homes. Taps call
/// [Navigator.maybePop], returning to the hub.
class AllGamesBackButton extends StatelessWidget {
  const AllGamesBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          Text('All Games',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.ink)),
        ],
      ),
    );
  }
}
