import 'package:flutter/material.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/confetti.dart';
import '../../../core/widgets/double_awards_button.dart';
import '../../../core/widgets/star_row.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/difficulty.dart';
import '../models/level.dart';
import '../services/game_state.dart';
import 'game_screen.dart';

/// The next level in play order after [level], or null if it's the last one.
GameLevel? _nextLevelAfter(GameLevel level) {
  final order = WorldMap.allLevels;
  final pos = order.indexWhere((l) => l.id == level.id);
  if (pos < 0 || pos + 1 >= order.length) return null;
  return order[pos + 1];
}

/// Celebratory results screen: stars, coins, XP, level-ups, badges, boss win.
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.level,
    required this.outcome,
    required this.correct,
    required this.total,
    required this.score,
    required this.bossDefeated,
    required this.heroSurvived,
  });

  final GameState state;
  final PlayerProfile profile;
  final GameLevel level;
  final LevelOutcome outcome;
  final int correct;
  final int total;
  final int score;
  final bool bossDefeated;
  final bool heroSurvived;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Convenience accessors so the existing build code needs minimal changes.
  GameState get state => widget.state;
  PlayerProfile get profile => widget.profile;
  GameLevel get level => widget.level;
  LevelOutcome get outcome => widget.outcome;
  int get correct => widget.correct;
  int get total => widget.total;
  int get score => widget.score;
  bool get bossDefeated => widget.bossDefeated;

  @override
  void initState() {
    super.initState();
    // Play reward sounds once as the screen appears (staggered).
    final fb = FeedbackService(enabled: state.soundOn);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && outcome.coinsEarned > 0) fb.coin();
    });
    if (outcome.leveledUp) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) fb.levelUp();
      });
    }
  }

  bool get _celebrate =>
      outcome.stars == 3 || bossDefeated || outcome.leveledUp;

  int get _percent => total == 0 ? 0 : ((correct / total) * 100).round();

  String get _title {
    if (level.isBoss) {
      return bossDefeated ? 'BOSS DEFEATED!' : 'THE BOSS ESCAPED!';
    }
    return outcome.stars == 3 ? 'QUEST COMPLETE!' : 'QUEST OVER!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [level.world.color, AppTheme.paper],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: 0.02,
                        child: ComicPanel(
                          color: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Text(
                            _title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: AppTheme.ink, offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ComicPanel(
                        child: Column(
                          children: [
                            StarRow(earned: outcome.stars, size: 46),
                            const SizedBox(height: 14),
                            Text('$correct / $total correct',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900)),
                            Text('$_percent%',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: level.world.color)),
                            const Divider(height: 26, thickness: 2),
                            _rewardRow('🪙', 'Coins earned',
                                '+${outcome.coinsEarned}'),
                            const SizedBox(height: 8),
                            _rewardRow('⚡', 'XP earned', '+${outcome.xpEarned}'),
                            if (outcome.elapsedSeconds > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 22),
                                  const SizedBox(width: 10),
                                  const Text('Your time',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  TimerChip(seconds: outcome.elapsedSeconds),
                                ],
                              ),
                            ],
                            if (outcome.isNewFastest) ...[
                              const SizedBox(height: 12),
                              _recordBanner('⚡ NEW FASTEST TIME!'),
                            ],
                            if (outcome.leveledUp) ...[
                              const SizedBox(height: 12),
                              _levelUpBanner(),
                            ],
                          ],
                        ),
                      ),
                      if (outcome.newAchievements.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _achievementsPanel(),
                      ],
                      const SizedBox(height: 16),
                      const DoubleAwardsButton(),
                      const SizedBox(height: 16),
                      _buildActions(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_celebrate) const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final next = _nextLevelAfter(level);
    // Next level is available once this one is cleared (earned a star). Boss
    // levels must be defeated to progress.
    final canAdvance = outcome.stars > 0 && (!level.isBoss || bossDefeated);
    final showNext = next != null && canAdvance;

    return Column(
      children: [
        if (showNext)
          ComicButton(
            label: 'Next Level',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      GameScreen(level: next, state: state, profile: profile),
                ),
              );
            },
          ),
        if (showNext) const SizedBox(height: 12),
        ComicButton(
          label: 'Back to Map',
          icon: Icons.map_rounded,
          color: showNext ? Colors.white : AppTheme.primary,
          textColor: showNext ? AppTheme.ink : Colors.white,
          fontSize: showNext ? 18 : 22,
          // Pop the result to return to the level map underneath.
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 12),
        ComicButton(
          label: 'Play Again',
          icon: Icons.replay_rounded,
          color: Colors.white,
          textColor: AppTheme.ink,
          fontSize: 18,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    GameScreen(level: level, state: state, profile: profile),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _rewardRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _recordBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.success,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ink, width: 2.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _levelUpBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ink, width: 2.5),
      ),
      child: Text(
        '🎉 LEVEL UP!  You are now Level ${outcome.newLevel}',
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _achievementsPanel() {
    return ComicPanel(
      color: Colors.white,
      child: Column(
        children: [
          const Text('New Award!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final a in outcome.newAchievements)
                Column(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 40)),
                    Text(a.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
