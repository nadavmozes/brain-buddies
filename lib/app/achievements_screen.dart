import 'package:flutter/material.dart';

import '../core/l10n/l10n.dart';
import '../core/models/achievement.dart';
import '../core/models/sticker.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/comic_panel.dart';

/// Hub-level awards area, shared across all games. Two tabs: the functional
/// achievements shelf (Awards) and the playful collectible sticker shelf
/// (Stickers). The sticker shelf lives here — reached from the Awards area —
/// so no extra hub button is needed.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.achievements,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          bottom: TabBar(
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            tabs: [
              Tab(text: context.l10n.achievements),
              Tab(text: context.l10n.stickerShelfTitle),
            ],
          ),
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: profile,
            builder: (context, _) => TabBarView(
              children: [
                _AwardsTab(profile: profile),
                _StickerTab(profile: profile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The original achievements shelf, now the first tab.
class _AwardsTab extends StatelessWidget {
  const _AwardsTab({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ComicPanel(
            color: AppTheme.accent,
            child: Text(
              context.l10n.earnedCount(
                  profile.achievementCount, Achievements.all.length),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            // Slightly taller tiles so the longest localized descriptions fit
            // within a 430px frame without a vertical overflow.
            childAspectRatio: 0.92,
            children: [
              for (final a in Achievements.all)
                _AchievementTile(
                    achievement: a, earned: profile.hasAchievement(a.id)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// The playful collectible sticker shelf, the second tab. Mirrors the awards
/// grid: earned stickers show their emoji; locked ones show '🔒' dimmed with
/// their requirement label.
class _StickerTab extends StatelessWidget {
  const _StickerTab({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final owned = profile.ownedStickers.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ComicPanel(
            color: AppTheme.accent,
            child: Text(
              context.l10n.earnedCount(owned, Stickers.all.length),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            // Slightly taller than the awards grid so a locked tile's extra
            // requirement line fits without overflow at 430px.
            childAspectRatio: 0.88,
            children: [
              for (final s in Stickers.all)
                _StickerTile(sticker: s, earned: profile.hasSticker(s.id)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.earned});

  final Achievement achievement;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: earned ? 1.0 : 0.45,
      child: ComicPanel(
        color: earned ? Colors.white : Colors.grey.shade200,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(earned ? achievement.emoji : '🔒',
                style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 6),
            Text(context.tr('ach.name', achievement.id, achievement.name),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                  context.tr(
                      'ach.desc', achievement.id, achievement.description),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({required this.sticker, required this.earned});

  final Sticker sticker;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final unlock = sticker.unlock;
    return Opacity(
      opacity: earned ? 1.0 : 0.45,
      child: ComicPanel(
        color: earned ? Colors.white : Colors.grey.shade200,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(earned ? sticker.emoji : '🔒',
                style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 6),
            Text(context.tr('sticker.name', sticker.id, sticker.name),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            if (!earned && unlock != null) ...[
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                    context.tr('sticker.unlock', sticker.id, unlock.label),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
