import 'package:flutter/material.dart';

import '../core/models/mission.dart';
import '../core/services/feedback_service.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/coin_pill.dart';
import '../core/widgets/comic_panel.dart';

/// The hub-level mission board: three daily missions with progress bars and
/// claimable coin rewards. Missions rotate daily and reset at midnight.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Missions',
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
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ComicPanel(
                color: AppTheme.primary,
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Day streak: ${profile.dailyStreak}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Today\'s Missions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              for (final m in profile.todaysMissions)
                _MissionCard(profile: profile, mission: m),
              const SizedBox(height: 8),
              const Text(
                'New missions arrive every day. Come back tomorrow!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.profile, required this.mission});

  final PlayerProfile profile;
  final MissionDef mission;

  @override
  Widget build(BuildContext context) {
    final progress = profile.missionProgress(mission.id);
    final complete = profile.missionComplete(mission);
    final claimed = profile.missionClaimed(mission.id);
    final ratio = (progress / mission.target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ComicPanel(
        color: claimed ? Colors.grey.shade200 : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(mission.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mission.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 14,
                backgroundColor: Colors.grey.shade200,
                color: complete ? AppTheme.success : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$progress / ${mission.target}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                _rewardButton(context, complete, claimed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardButton(BuildContext context, bool complete, bool claimed) {
    if (claimed) {
      return const Text('Claimed ✓',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800));
    }
    final canClaim = complete;
    return GestureDetector(
      onTap: canClaim
          ? () async {
              final coins = await profile.claimMission(mission);
              if (!context.mounted) return;
              FeedbackService(enabled: profile.soundOn).coin();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('+$coins coins! 🪙')),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: canClaim ? AppTheme.accent : Colors.grey.shade300,
          border: Border.all(color: AppTheme.ink, width: 2.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          canClaim ? 'Claim 🪙 ${mission.rewardCoins}' : '🪙 ${mission.rewardCoins}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
