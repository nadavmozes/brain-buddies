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
import '../models/habitat.dart';
import '../models/safari_level.dart';
import '../services/safari_state.dart';
import 'safari_game_screen.dart';

/// The next trail level after [level], or null if it's the last one.
SafariLevel? _nextLevelAfter(SafariLevel level) {
  final order = SafariMap.allLevels;
  final pos = order.indexWhere((l) => l.id == level.id);
  if (pos < 0 || pos + 1 >= order.length) return null;
  return order[pos + 1];
}

/// Shape Safari results for a trail level: stars, coins, guardian befriended,
/// new-best banner, confetti.
class SafariResultScreen extends StatefulWidget {
  const SafariResultScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.level,
    required this.outcome,
    required this.correct,
    required this.total,
  });

  final SafariState state;
  final PlayerProfile profile;
  final SafariLevel level;
  final SafariOutcome outcome;
  final int correct;
  final int total;

  @override
  State<SafariResultScreen> createState() => _SafariResultScreenState();
}

class _SafariResultScreenState extends State<SafariResultScreen> {
  int get _percent =>
      widget.total == 0 ? 0 : ((widget.correct / widget.total) * 100).round();

  bool get _befriended => widget.outcome.guardianBefriended;

  bool get _celebrate =>
      widget.outcome.stars == 3 ||
      widget.outcome.isNewBest ||
      widget.outcome.isNewFastest ||
      _befriended;

  String _titleFor(AppStrings l) {
    if (widget.level.isGuardian) {
      return _befriended ? l.safariTitleBefriended : l.safariTitleAlmost;
    }
    return widget.outcome.stars == 3 ? l.safariTitleGreat : l.safariTitleDone;
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
                colors: [level.habitat.color, AppTheme.paper],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (level.isGuardian)
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
                                    color: level.habitat.color)),
                            const Divider(height: 26, thickness: 2),
                            RewardRow(
                              leading: const Text('🪙',
                                  style: TextStyle(fontSize: 22)),
                              label: l.coinsEarned,
                              value: '+${outcome.coinsEarned}',
                            ),
                            if (outcome.elapsedSeconds > 0) ...[
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
                            ],
                            if (_befriended) ...[
                              const SizedBox(height: 12),
                              ResultBanner(l.safariFriendBanner(context.tr(
                                  'ss.guardian.name',
                                  level.habitat.name,
                                  level.guardian.name))),
                            ],
                            if (outcome.isNewFastest) ...[
                              const SizedBox(height: 12),
                              ResultBanner(l.newFastestTime),
                            ] else if (outcome.isNewBest && !_befriended) ...[
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
    // Advance once this stop is cleared (earned a star). Guardian stops must
    // be befriended to progress.
    final canAdvance =
        widget.outcome.stars > 0 && (!level.isGuardian || _befriended);
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
                  builder: (_) => SafariGameScreen(
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
          // Pop the result to return to the trail map underneath.
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
                builder: (_) => SafariGameScreen(
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
