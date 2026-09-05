import 'package:flutter/material.dart';

import '../core/models/achievement.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/comic_panel.dart';

/// Hub-level achievements shelf, shared across all games.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: profile,
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ComicPanel(
                  color: AppTheme.accent,
                  child: Text(
                    '${profile.achievementCount} / ${Achievements.all.length} earned',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  children: [
                    for (final a in Achievements.all)
                      _AchievementTile(
                          achievement: a, earned: profile.hasAchievement(a.id)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
            Text(achievement.name,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(achievement.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
