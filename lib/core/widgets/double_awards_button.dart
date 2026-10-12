import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// A "Double Awards" button styled like a watch-an-ad reward prompt, shown
/// grayed out with a "Coming Soon" label. Not wired to any ad SDK yet.
class DoubleAwardsButton extends StatelessWidget {
  const DoubleAwardsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          border: Border.all(color: AppTheme.ink, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.smart_display_rounded,
                    color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Text(
                  context.l10n.doubleAwards,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('x2',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.watchVideoComingSoon,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
