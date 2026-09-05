import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';
import '../models/difficulty.dart';
import '../models/level.dart';
import '../services/game_state.dart';
import 'level_map_screen.dart';

/// World select: pick a difficulty world to open its level map.
class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key, required this.state, required this.profile});

  final GameState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your World',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final difficulty in Difficulty.values) ...[
              _WorldCard(
                  difficulty: difficulty, state: state, profile: profile),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard(
      {required this.difficulty, required this.state, required this.profile});

  final Difficulty difficulty;
  final GameState state;
  final PlayerProfile profile;

  int _worldStars() {
    final world = WorldMap.world(difficulty);
    return world.levels.fold(0, (sum, l) => sum + state.stars(l.id));
  }

  @override
  Widget build(BuildContext context) {
    final maxStars = WorldMap.levelsPerWorld * 3;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LevelMapScreen(
                state: state, profile: profile, difficulty: difficulty),
          ),
        );
      },
      child: ComicPanel(
        color: difficulty.color,
        child: Row(
          children: [
            Text(difficulty.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${difficulty.label} World',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: AppTheme.ink, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    difficulty.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: state,
                    builder: (context, _) => Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accent, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          '${_worldStars()} / $maxStars',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 36),
          ],
        ),
      ),
    );
  }
}
