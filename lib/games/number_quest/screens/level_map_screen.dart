import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/trail_map.dart';
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
    final s = context.l10n;
    final label =
        context.tr('nq.difficulty.label', difficulty.name, difficulty.label);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.worldTitle(difficulty.emoji, label),
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
          child: TrailMapView(
            listenable: state,
            pathColor: difficulty.color,
            nodes: [
              for (final level in world.levels) _nodeFor(context, level),
            ],
          ),
        ),
      ),
    );
  }

  TrailNodeData _nodeFor(BuildContext context, GameLevel level) {
    final unlocked = state.isLevelUnlocked(level);
    final s = context.l10n;
    final title = level.isBoss ? s.bossUpper : s.levelN(level.number);
    return TrailNodeData(
      label: level.isBoss ? level.boss.emoji : '${level.number}',
      title: title,
      color: level.isBoss ? const Color(0xFF7E57C2) : level.world.color,
      unlocked: unlocked,
      stars: state.stars(level.id),
      isBoss: level.isBoss,
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
    );
  }
}
