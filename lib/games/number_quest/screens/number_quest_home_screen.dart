import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coin_pill.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/xp_bar.dart';
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
                          Text('All Games',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink)),
                        ],
                      ),
                    ),
                  ),
                ),
                _Hud(state: state, profile: profile),
                const SizedBox(height: 16),
                const _TitleBanner(),
                const SizedBox(height: 20),
                ComicButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow_rounded,
                  fontSize: 28,
                  onPressed: () => _push(
                      context, DifficultyScreen(state: state, profile: profile)),
                ),
                const SizedBox(height: 14),
                ComicButton(
                  label: 'Daily Challenge',
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
                        label: 'Progress',
                        icon: Icons.insights_rounded,
                        color: Colors.white,
                        textColor: AppTheme.ink,
                        fontSize: 18,
                        onPressed: () =>
                            _push(context, ParentScreen(state: state)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ComicButton(
                        label: 'Settings',
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
                  child: const Text('How to Play',
                      style: TextStyle(
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
        title: const Text('How to Play',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          '1. Pick a world and follow the level path.\n\n'
          '2. Tap the right answer. Chain answers for a streak bonus!\n\n'
          '3. Earn coins and XP. Beat the boss at the end of each world.\n\n'
          '4. Spend coins in the hub Shop, collect awards, and play every day '
          'to grow your streak!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!',
                style: TextStyle(fontWeight: FontWeight.w800)),
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
          const SizedBox(width: 10),
          XpBar(level: state.level, progress: state.levelProgress, width: 90),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.ink, width: 2.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('${state.dailyStreak}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          CoinPill(amount: profile.coins),
        ],
      ),
    );
  }
}

class _TitleBanner extends StatelessWidget {
  const _TitleBanner();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: ComicPanel(
        color: AppTheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Column(
          children: const [
            Text(
              'NUMBER',
              style: TextStyle(
                fontSize: 48,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: AppTheme.accent,
                letterSpacing: 2,
                shadows: [Shadow(color: AppTheme.ink, offset: Offset(3, 3))],
              ),
            ),
            Text(
              'QUEST',
              style: TextStyle(
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
