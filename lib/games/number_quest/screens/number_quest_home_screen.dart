import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/all_games_back_button.dart';
import '../../../core/widgets/coin_pill.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/stat_chip.dart';
import '../models/level.dart';
import '../services/game_state.dart';
import '../widgets/hero_buddy.dart';
import 'difficulty_screen.dart';
import 'game_screen.dart';
import 'parent_screen.dart';
import 'settings_screen.dart';

/// The Number Quest landing screen: title, HUD, and menu. Coins and the avatar
/// come from the shared [PlayerProfile]; XP/level/streak are Number Quest's own.
class NumberQuestHome extends StatelessWidget {
  const NumberQuestHome({
    super.key,
    required this.state,
    required this.profile,
  });

  final GameState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.sky, AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: AllGamesBackButton(),
                  ),
                ),
                _Hud(state: state, profile: profile),
                const SizedBox(height: 16),
                _TitleBanner(),
                const SizedBox(height: 20),
                ComicButton(
                  label: context.l10n.play,
                  icon: Icons.play_arrow_rounded,
                  fontSize: 28,
                  onPressed: () => _push(
                      context, DifficultyScreen(state: state, profile: profile)),
                ),
                const SizedBox(height: 14),
                ComicButton(
                  label: context.l10n.dailyChallenge,
                  icon: Icons.calendar_today_rounded,
                  color: AppTheme.accent,
                  textColor: AppTheme.ink,
                  fontSize: 20,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          level: WorldMap.dailyLevel(),
                          state: state,
                          profile: profile,
                          isDaily: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ComicButton(
                        label: context.l10n.progress,
                        icon: Icons.insights_rounded,
                        color: Colors.white,
                        textColor: AppTheme.ink,
                        fontSize: 18,
                        onPressed: () => _push(context,
                            ParentScreen(state: state, profile: profile)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ComicButton(
                        label: context.l10n.settings,
                        icon: Icons.settings_rounded,
                        color: Colors.white,
                        textColor: AppTheme.ink,
                        fontSize: 18,
                        onPressed: () => _push(context,
                            SettingsScreen(state: state, profile: profile)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _showHowTo(context),
                  child: Text(context.l10n.howToPlay,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: AppTheme.ink)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showHowTo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.ink, width: 3),
        ),
        title: Text(context.l10n.howToPlay,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          context.l10n.howToPlayBody,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.gotIt,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.state, required this.profile});

  final GameState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([state, profile]),
      builder: (context, _) => Row(
        children: [
          HeroBuddy(
            mood: BuddyMood.idle,
            size: 44,
            heroEmoji: profile.selectedAvatar.emoji,
            baseColor: profile.selectedAvatar.color,
          ),
          const Spacer(),
          StatChip(leading: '🔥', value: '${profile.dailyStreak}'),
          const SizedBox(width: 8),
          CoinPill(amount: profile.coins),
        ],
      ),
    );
  }
}

class _TitleBanner extends StatelessWidget {
  _TitleBanner();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: ComicPanel(
        color: AppTheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Column(
          children: [
            Text(
              context.l10n.nqLogoLine1,
              style: const TextStyle(
                fontSize: 48,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: AppTheme.accent,
                letterSpacing: 2,
                shadows: [Shadow(color: AppTheme.ink, offset: Offset(3, 3))],
              ),
            ),
            Text(
              context.l10n.nqLogoLine2,
              style: const TextStyle(
                fontSize: 44,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
                shadows: [Shadow(color: AppTheme.ink, offset: Offset(3, 3))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
