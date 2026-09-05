import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/star_row.dart';
import '../models/difficulty.dart';
import '../models/level.dart';
import '../services/game_state.dart';
import 'game_screen.dart';

/// A winding-path map of levels for one world (difficulty).
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.difficulty,
  });

  final GameState state;
  final PlayerProfile profile;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final world = WorldMap.world(difficulty);
    return Scaffold(
      appBar: AppBar(
        title: Text('${difficulty.emoji} ${difficulty.label} World',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [difficulty.color.withOpacity(0.35), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: state,
            builder: (context, _) => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24),
              itemCount: world.length,
              itemBuilder: (context, i) {
                final level = world.levels[i];
                // Alternate left/right for a winding-path feel.
                final alignLeft = i.isEven;
                return _LevelNode(
                  state: state,
                  profile: profile,
                  level: level,
                  alignLeft: alignLeft,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.state,
    required this.profile,
    required this.level,
    required this.alignLeft,
  });

  final GameState state;
  final PlayerProfile profile;
  final GameLevel level;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final unlocked = state.isLevelUnlocked(level);
    final stars = state.stars(level.id);

    final node = GestureDetector(
      onTap: unlocked
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      GameScreen(level: level, state: state, profile: profile),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: unlocked ? 1 : 0.5,
        child: ComicPanel(
          color: level.isBoss
              ? const Color(0xFF7E57C2)
              : (unlocked ? level.world.color : Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.isBoss
                    ? level.boss.emoji
                    : (unlocked ? '${level.number}' : '🔒'),
                style: TextStyle(
                  fontSize: level.isBoss ? 36 : 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: AppTheme.ink, offset: Offset(2, 2)),
                  ],
                ),
              ),
              Text(
                level.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (unlocked) ...[
                const SizedBox(height: 4),
                StarRow(earned: stars, size: 18),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: alignLeft ? 32 : 0,
        right: alignLeft ? 0 : 32,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        mainAxisAlignment:
            alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!alignLeft) const _Connector(),
          node,
          if (alignLeft) const _Connector(),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      child: Icon(Icons.more_horiz_rounded, color: AppTheme.ink),
    );
  }
}
