import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/confetti.dart';
import '../../../core/widgets/double_awards_button.dart';
import '../../../core/widgets/pet_round_moment.dart';
import '../../../core/widgets/result_banner.dart';
import '../../../core/widgets/reward_row.dart';
import '../../../core/widgets/star_row.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/money_level.dart';
import '../services/money_state.dart';
import 'money_game_screen.dart';

MoneyLevel? _nextLevelAfter(MoneyLevel level) {
  final order = MoneyMap.allLevels;
  final pos = order.indexWhere((l) => l.id == level.id);
  if (pos < 0 || pos + 1 >= order.length) return null;
  return order[pos + 1];
}

/// Money Math results: stars, coins, time, new-record banner, confetti.
class MoneyResultScreen extends StatefulWidget {
  const MoneyResultScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.level,
    required this.outcome,
    required this.correct,
    required this.total,
  });

  final MoneyState state;
  final PlayerProfile profile;
  final MoneyLevel level;
  final MoneyOutcome outcome;
  final int correct;
  final int total;

  @override
  State<MoneyResultScreen> createState() => _MoneyResultScreenState();
}

class _MoneyResultScreenState extends State<MoneyResultScreen> {
  int get _percent =>
      widget.total == 0 ? 0 : ((widget.correct / widget.total) * 100).round();

  bool get _celebrate =>
      widget.outcome.stars == 3 ||
      widget.outcome.isNewFastest ||
      widget.outcome.bossBeaten;

  String _titleFor(AppStrings l) {
    if (widget.level.isBoss) {
      return widget.outcome.bossBeaten
          ? l.moneyTitleGuardianPaid
          : l.moneyTitleAlmost;
    }
    return widget.outcome.stars == 3 ? l.moneyTitleMaster : l.moneyTitleNice;
  }

  @override
  void initState() {
    super.initState();
    final fb = FeedbackService(enabled: widget.state.soundOn);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && widget.outcome.coinsEarned > 0) fb.coin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.outcome;
    final level = widget.level;
    final l = context.l10n;
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
                      if (level.isBoss)
                        Text(level.guardian.emoji,
                            style: const TextStyle(fontSize: 64)),
                      Transform.rotate(
                        angle: 0.02,
                        child: ComicPanel(
                          color: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          child: Text(
                            _titleFor(l),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: AppTheme.ink, offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      ComicPanel(
                        child: Column(
                          children: [
                            StarRow(earned: outcome.stars, size: 44),
                            const SizedBox(height: 14),
                            Text(l.correctOfTotal(widget.correct, widget.total),
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w900)),
                            Text('$_percent%',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: level.world.color)),
                            const Divider(height: 24, thickness: 2),
                            RewardRow(
                              leading: const Text('🪙',
                                  style: TextStyle(fontSize: 22)),
                              label: l.coinsEarned,
                              value: '+${outcome.coinsEarned}',
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 22),
                                const SizedBox(width: 8),
                                Text(l.yourTime,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700)),
                                const Spacer(),
                                TimerChip(seconds: outcome.elapsedSeconds),
                              ],
                            ),
                            if (outcome.isNewFastest) ...[
                              const SizedBox(height: 12),
                              ResultBanner(l.newFastestTime),
                            ] else if (outcome.isNewBestScore) ...[
                              const SizedBox(height: 12),
                              ResultBanner(l.newBestScore),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      PetRoundMoment(profile: widget.profile),
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
    final l = context.l10n;
    final level = widget.level;
    final next = _nextLevelAfter(level);
    final canAdvance = widget.outcome.stars > 0 &&
        (!level.isBoss || widget.outcome.bossBeaten);
    final showNext = next != null && canAdvance;

    return Column(
      children: [
        if (showNext)
          ComicButton(
            label: l.nextStop,
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => MoneyGameScreen(
                      state: widget.state,
                      profile: widget.profile,
                      level: next),
                ),
              );
            },
          ),
        if (showNext) const SizedBox(height: 12),
        ComicButton(
          label: l.backToTrail,
          icon: Icons.map_rounded,
          color: showNext ? Colors.white : AppTheme.primary,
          textColor: showNext ? AppTheme.ink : Colors.white,
          fontSize: showNext ? 18 : 22,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 12),
        ComicButton(
          label: l.playAgain,
          icon: Icons.replay_rounded,
          color: Colors.white,
          textColor: AppTheme.ink,
          fontSize: 18,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MoneyGameScreen(
                    state: widget.state,
                    profile: widget.profile,
                    level: level),
              ),
            );
          },
        ),
      ],
    );
  }

}
