import 'package:flutter/material.dart';

import '../core/l10n/l10n.dart';
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
        title: Text(context.l10n.avatarShop,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
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
            childAspectRatio: 0.78,
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
    final comingSoon = avatar.comingSoon;
    final gated = avatar.unlock != null;
    final gatedLocked = gated && !owned && !profile.isAvatarUnlocked(avatar);

    // Grey out both premium "coming soon" and gated-but-still-locked avatars.
    final dimmed = comingSoon || gatedLocked;

    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: ComicPanel(
        color: avatar.color,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(avatar.emoji, style: const TextStyle(fontSize: 40)),
            Text(
              context.tr('avatar.name', avatar.id, avatar.name),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: AppTheme.ink, offset: Offset(1.5, 1.5))],
              ),
            ),
            _action(context, owned, selected, comingSoon),
          ],
        ),
      ),
    );
  }

  Widget _action(
      BuildContext context, bool owned, bool selected, bool comingSoon) {
    if (comingSoon) {
      // Premium / coming soon: show real-money price + "Coming Soon".
      return Column(
        children: [
          _pill(avatar.priceLabel ?? '\$1.99', Colors.white, AppTheme.ink),
          const SizedBox(height: 4),
          Text(context.l10n.comingSoon,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      );
    }
    if (selected) {
      return _pill(context.l10n.equipped, Colors.white, AppTheme.ink);
    }
    if (owned) {
      return GestureDetector(
        onTap: () {
          profile.selectAvatar(avatar.id);
          FeedbackService(enabled: profile.soundOn).correct();
        },
        child: _pill(context.l10n.equip, AppTheme.ink, Colors.white),
      );
    }

    // Gated avatars: either still locked (show requirement + progress) or
    // unlocked-not-owned (claim, free or with coins).
    final unlock = avatar.unlock;
    if (unlock != null) {
      final unlocked = profile.isAvatarUnlocked(avatar);
      if (!unlocked) return _lockedHint(unlock);
      return _claimAction(context);
    }

    // Plain coin-buy avatar.
    final canAfford = profile.coins >= avatar.cost;
    return GestureDetector(
      onTap: () => _buy(context),
      child: _pill(context.l10n.coinCost(avatar.cost),
          canAfford ? AppTheme.accent : Colors.grey.shade300, AppTheme.ink),
    );
  }

  /// The locked state for a gated avatar: a tiny progress bar plus the kid-
  /// facing requirement label. Sized via [LayoutBuilder] so it never grows the
  /// tile from the screen width (per coding conventions) and wraps if needed.
  Widget _lockedHint(AvatarUnlock unlock) {
    final progress = profile.avatarUnlockProgress(avatar).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.lockedRequirement(
                  context.tr('avatar.unlock', avatar.id, unlock.label)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(color: AppTheme.ink, offset: Offset(1, 1)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// The claimable state for a gated avatar whose requirement is met.
  Widget _claimAction(BuildContext context) {
    final free = avatar.cost == 0;
    final canAfford = free || profile.coins >= avatar.cost;
    final label =
        free ? context.l10n.claimGift : context.l10n.claimCost(avatar.cost);
    return GestureDetector(
      onTap: () => _claim(context),
      child: _pill(
        label,
        canAfford ? AppTheme.accent : Colors.grey.shade300,
        AppTheme.ink,
      ),
    );
  }

  Future<void> _buy(BuildContext context) async {
    final ok = await profile.buyAvatar(avatar);
    if (!context.mounted) return;
    final fb = FeedbackService(enabled: profile.soundOn);
    final name = context.tr('avatar.name', avatar.id, avatar.name);
    if (ok) {
      fb.celebrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.unlockedAvatar(name))),
      );
    } else {
      fb.wrong();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notEnoughCoins)),
      );
    }
  }

  Future<void> _claim(BuildContext context) async {
    final ok = await profile.claimAvatar(avatar);
    if (!context.mounted) return;
    final fb = FeedbackService(enabled: profile.soundOn);
    final name = context.tr('avatar.name', avatar.id, avatar.name);
    if (ok) {
      fb.celebrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.unlockedAvatar(name))),
      );
    } else {
      fb.wrong();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notEnoughCoins)),
      );
    }
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
