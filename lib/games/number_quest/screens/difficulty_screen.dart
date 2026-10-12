import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';
import '../models/difficulty.dart';
import '../models/level.dart';
import '../services/game_state.dart';
import 'level_map_screen.dart';
import 'times_tables_map_screen.dart';

/// World select: pick a difficulty world to open its level map.
class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key, required this.state, required this.profile});

  final GameState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.chooseYourWorld,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
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
            _TimesTablesCard(state: state, profile: profile),
            const SizedBox(height: 20),
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
                    context.l10n.worldLabel(context.tr(
                        'nq.difficulty.label', difficulty.name,
                        difficulty.label)),
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
                    context.tr('nq.difficulty.subtitle', difficulty.name,
                        difficulty.subtitle),
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
            Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Times Tables campaign tile. Routed separately from the three difficulty
/// worlds into its own trail. Styled like [_WorldCard] for a consistent look.
class _TimesTablesCard extends StatelessWidget {
  const _TimesTablesCard({required this.state, required this.profile});

  final GameState state;
  final PlayerProfile profile;

  int _worldStars() =>
      TimesTablesMap.allLevels.fold(0, (sum, l) => sum + state.stars(l.id));

  @override
  Widget build(BuildContext context) {
    final maxStars = TimesTablesMap.levelCount * 3;
    final label = context.l10n.nqTimesTablesLabel;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TimesTablesMapScreen(state: state, profile: profile),
          ),
        );
      },
      child: ComicPanel(
        color: TimesTablesMap.color,
        child: Row(
          children: [
            const Text(TimesTablesMap.emoji,
                style: TextStyle(fontSize: 44)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.worldLabel(label),
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
                    context.l10n.nqTimesTablesSubtitle,
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
            Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}
