import 'package:flutter/material.dart';

import '../core/models/avatar.dart';
import '../core/services/feedback_service.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/coin_pill.dart';
import '../core/widgets/comic_panel.dart';

/// The hub-level Avatar Shop: buy avatars with coins, equip owned ones, and
/// preview the premium ("coming soon") avatar.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Shop',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: AnimatedBuilder(
                animation: profile,
                builder: (_, __) => CoinPill(amount: profile.coins),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: profile,
          builder: (context, _) => GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.82,
            children: [
              for (final avatar in Avatars.all)
                _AvatarCard(profile: profile, avatar: avatar),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.profile, required this.avatar});

  final PlayerProfile profile;
  final Avatar avatar;

  @override
  Widget build(BuildContext context) {
    final owned = profile.ownsAvatar(avatar.id);
    final selected = profile.selectedAvatarId == avatar.id;
    final locked = avatar.comingSoon;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: ComicPanel(
        color: avatar.color,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(avatar.emoji, style: const TextStyle(fontSize: 40)),
            Text(
              avatar.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: AppTheme.ink, offset: Offset(1.5, 1.5))],
              ),
            ),
            _action(context, owned, selected, locked),
          ],
        ),
      ),
    );
  }

  Widget _action(
      BuildContext context, bool owned, bool selected, bool locked) {
    if (locked) {
      // Premium / coming soon: show real-money price + "Coming Soon".
      return Column(
        children: [
          _pill(avatar.priceLabel ?? '\$1.99', Colors.white, AppTheme.ink),
          const SizedBox(height: 4),
          const Text('Coming Soon',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      );
    }
    if (selected) return _pill('Equipped ✓', Colors.white, AppTheme.ink);
    if (owned) {
      return GestureDetector(
        onTap: () {
          profile.selectAvatar(avatar.id);
          FeedbackService(enabled: profile.soundOn).correct();
        },
        child: _pill('Equip', AppTheme.ink, Colors.white),
      );
    }
    final canAfford = profile.coins >= avatar.cost;
    return GestureDetector(
      onTap: () async {
        final ok = await profile.buyAvatar(avatar);
        if (!context.mounted) return;
        final fb = FeedbackService(enabled: profile.soundOn);
        if (ok) {
          fb.celebrate();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unlocked ${avatar.name}! 🎉')),
          );
        } else {
          fb.wrong();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough coins yet!')),
          );
        }
      },
      child: _pill('🪙 ${avatar.cost}',
          canAfford ? AppTheme.accent : Colors.grey.shade300, AppTheme.ink),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppTheme.ink, width: 2.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }
}
