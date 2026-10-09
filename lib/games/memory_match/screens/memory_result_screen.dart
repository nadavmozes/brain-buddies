import 'package:flutter/material.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/confetti.dart';
import '../../../core/widgets/double_awards_button.dart';
import '../../../core/widgets/star_row.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/memory_level.dart';
import '../services/memory_state.dart';
import 'memory_game_screen.dart';

MemoryLevel? _nextLevelAfter(MemoryLevel level) {
  final order = MemoryMap.allLevels;
  final pos = order.indexWhere((l) => l.id == level.id);
  if (pos < 0 || pos + 1 >= order.length) return null;
  return order[pos + 1];
}

/// Memory Match results: stars, coins, time, perfect banner, confetti.
class MemoryResultScreen extends StatefulWidget {
  const MemoryResultScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.level,
    required this.outcome,
  });

  final MemoryState state;
  final PlayerProfile profile;
  final MemoryLevel level;
  final MemoryOutcome outcome;

  @override
  State<MemoryResultScreen> createState() => _MemoryResultScreenState();
}

class _MemoryResultScreenState extends State<MemoryResultScreen> {
  bool get _celebrate =>
      widget.outcome.stars == 3 ||
      widget.outcome.isNewFastest ||
      widget.outcome.perfect;

  String get _title {
    if (widget.level.isBoss) return 'GUARDIAN MATCHED!';
    return widget.outcome.perfect ? 'PERFECT MEMORY!' : 'WELL MATCHED!';
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
                            _title,
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
                            Text(
                              outcome.perfect
                                  ? 'No mistakes!'
                                  : 'Board cleared!',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const Divider(height: 24, thickness: 2),
                            Row(
                              children: [
                                const Text('🪙',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                const Text('Coins earned',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text('+${outcome.coinsEarned}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 22),
                                const SizedBox(width: 8),
                                const Text('Your time',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700)),
                                const Spacer(),
                                TimerChip(seconds: outcome.elapsedSeconds),
                              ],
                            ),
                            if (outcome.isNewFastest) ...[
                              const SizedBox(height: 12),
                              _banner('⚡ NEW FASTEST TIME!'),
                            ],
                          ],
                        ),
                      ),
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
    final level = widget.level;
    final next = _nextLevelAfter(level);
    // Memory Match always awards at least 1 star for finishing, so any finish
    // unlocks the next stop.
    final showNext = next != null && widget.outcome.stars > 0;

    return Column(
      children: [
        if (showNext)
          ComicButton(
            label: 'Next Stop',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => MemoryGameScreen(
                      state: widget.state,
                      profile: widget.profile,
                      level: next),
                ),
              );
            },
          ),
        if (showNext) const SizedBox(height: 12),
        ComicButton(
          label: 'Back to Trail',
          icon: Icons.map_rounded,
          color: showNext ? Colors.white : AppTheme.primary,
          textColor: showNext ? AppTheme.ink : Colors.white,
          fontSize: showNext ? 18 : 22,
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
                builder: (_) => MemoryGameScreen(
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

  Widget _banner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary,
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
}
