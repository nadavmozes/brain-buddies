import 'package:flutter/material.dart';

import '../core/l10n/l10n.dart';
import '../core/models/daily_reward.dart';
import '../core/models/game_catalog.dart';
import '../core/services/feedback_service.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/coin_pill.dart';
import '../core/widgets/comic_button.dart';
import '../core/widgets/comic_panel.dart';
import '../core/widgets/confetti.dart';

/// The hub "Daily" surface. Combines the 7-day login-reward calendar + a
/// "play all 6 today" tracker at the top, and a "Play today's challenge" button
/// that routes into the existing Number Quest daily challenge via [onPlayDaily].
///
/// Uses LayoutBuilder (never MediaQuery.size) and EdgeInsetsDirectional so the
/// 7 boxes and 6-icon row stay correct in Hebrew RTL at 430px.
class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({
    super.key,
    required this.profile,
    required this.onPlayDaily,
  });

  final PlayerProfile profile;

  /// Opens the existing Number Quest daily challenge (the hub owns the NQ
  /// state and navigation, so it is passed in as a callback).
  final VoidCallback onPlayDaily;

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  bool _showConfetti = false;

  PlayerProfile get _profile => widget.profile;

  Future<void> _claimLogin() async {
    final reward = await _profile.claimDailyLogin();
    if (reward == null || !mounted) return;
    FeedbackService(enabled: _profile.soundOn).coin();
    setState(() => _showConfetti = true);
    final coins = reward.kind == DailyRewardKind.petTreat ? 0 : reward.amount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.dailyRewardClaimedToast(coins))),
    );
  }

  Future<void> _claimAllSix() async {
    final coins = await _profile.claimAllSixBonus();
    if (coins <= 0 || !mounted) return;
    FeedbackService(enabled: _profile.soundOn).coin();
    setState(() => _showConfetti = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.coinsGained(coins))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.dailyRewardTitle,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: AnimatedBuilder(
                animation: _profile,
                builder: (_, __) => CoinPill(amount: _profile.coins),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.sky, AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _profile,
                builder: (context, _) => LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CalendarPanel(
                          profile: _profile,
                          maxWidth: constraints.maxWidth,
                          onClaim: _claimLogin,
                        ),
                        const SizedBox(height: 16),
                        _AllSixPanel(
                          profile: _profile,
                          onClaim: _claimAllSix,
                        ),
                        const SizedBox(height: 16),
                        ComicButton(
                          label: context.l10n.playTodaysChallenge,
                          icon: Icons.play_arrow_rounded,
                          color: AppTheme.primary,
                          onPressed: widget.onPlayDaily,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showConfetti)
                const Positioned.fill(child: Confetti()),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 7-day login-reward calendar: a wrapping grid of reward boxes with
/// claimed / today (claimable) / upcoming states and a CLAIM button.
class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.profile,
    required this.maxWidth,
    required this.onClaim,
  });

  final PlayerProfile profile;
  final double maxWidth;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final canClaim = profile.canClaimDailyLogin;
    final currentIndex = profile.loginCycleIndex;
    // 4 boxes per row at phone width; sized from the panel width (not
    // MediaQuery) so it is correct inside the 430px frame.
    const perRow = 4;
    const gap = 10.0;
    // ComicPanel default padding is 20 on each side.
    final innerWidth = maxWidth - 40;
    final boxSize =
        ((innerWidth - gap * (perRow - 1)) / perRow).clamp(56.0, 100.0);

    return ComicPanel(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.dailyRewardTitle,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < DailyRewards.length; i++)
                _RewardBox(
                  def: DailyRewards.atIndex(i),
                  size: boxSize,
                  // Boxes before the current index this cycle are "claimed".
                  claimed: i < currentIndex,
                  isToday: i == currentIndex,
                  claimableToday: i == currentIndex && canClaim,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (canClaim)
            ComicButton(
              label: context.l10n.dailyRewardClaim,
              icon: Icons.card_giftcard_rounded,
              color: AppTheme.accent,
              textColor: AppTheme.ink,
              onPressed: onClaim,
            )
          else
            Center(
              child: Text(
                context.l10n.dailyRewardComeBack,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardBox extends StatelessWidget {
  const _RewardBox({
    required this.def,
    required this.size,
    required this.claimed,
    required this.isToday,
    required this.claimableToday,
  });

  final DailyRewardDef def;
  final double size;
  final bool claimed;
  final bool isToday;
  final bool claimableToday;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (claimableToday) {
      bg = AppTheme.accent;
    } else if (isToday) {
      // Today but already claimed this cycle position.
      bg = AppTheme.sky;
    } else if (claimed) {
      bg = AppTheme.success;
    } else {
      bg = Colors.grey.shade200;
    }

    return SizedBox(
      width: size,
      height: size + 26,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: AppTheme.ink,
            width: claimableToday ? 3.5 : 2.5,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              claimableToday ? AppTheme.comicShadow(offset: 4) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.dailyRewardDay(def.dayIndex + 1),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(claimed ? '✅' : def.emoji,
                style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              context.l10n.dailyRewardLabel(def.labelKey, def.amount),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 6-icon tracker row: each game's emoji lights up as it is played today.
/// Shows a claim button when all 6 are done.
class _AllSixPanel extends StatelessWidget {
  const _AllSixPanel({required this.profile, required this.onClaim});

  final PlayerProfile profile;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final played = profile.allSixPlayedToday;
    final canClaim = profile.canClaimAllSix;
    final claimedToday =
        profile.allSixProgress >= GameCatalog.all.length && !canClaim;

    return ComicPanel(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.playAll6Title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                context.l10n.playAll6Progress(
                    profile.allSixProgress, GameCatalog.all.length),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final game in GameCatalog.all)
                _GameDot(
                  emoji: game.emoji,
                  lit: played.contains(game.id),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (canClaim)
            ComicButton(
              label: context.l10n.playAll6Claim,
              icon: Icons.redeem_rounded,
              color: AppTheme.accent,
              textColor: AppTheme.ink,
              onPressed: onClaim,
            )
          else if (claimedToday)
            Center(
              child: Text(
                context.l10n.playAll6Claimed,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameDot extends StatelessWidget {
  const _GameDot({required this.emoji, required this.lit});

  final String emoji;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lit ? AppTheme.success : Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.ink, width: 2.5),
      ),
      child: Opacity(
        opacity: lit ? 1 : 0.45,
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
