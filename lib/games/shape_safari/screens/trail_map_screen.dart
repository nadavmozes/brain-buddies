import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/star_row.dart';
import '../models/habitat.dart';
import '../models/safari_level.dart';
import '../services/safari_state.dart';
import 'safari_game_screen.dart';

/// A winding trail of stops for one habitat, ending in a guardian.
class TrailMapScreen extends StatelessWidget {
  const TrailMapScreen(
      {super.key,
      required this.state,
      required this.profile,
      required this.habitat});

  final SafariState state;
  final PlayerProfile profile;
  final Habitat habitat;

  @override
  Widget build(BuildContext context) {
    final trail = SafariMap.trail(habitat);
    return Scaffold(
      appBar: AppBar(
        title: Text('${habitat.emoji} ${habitat.label} Trail',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [habitat.color.withOpacity(0.35), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: state,
            builder: (context, _) => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24),
              itemCount: trail.length,
              itemBuilder: (context, i) => _TrailNode(
                state: state,
                profile: profile,
                level: trail.levels[i],
                alignLeft: i.isEven,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailNode extends StatelessWidget {
  const _TrailNode({
    required this.state,
    required this.profile,
    required this.level,
    required this.alignLeft,
  });

  final SafariState state;
  final PlayerProfile profile;
  final SafariLevel level;
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
                  builder: (_) => SafariGameScreen(
                      state: state, profile: profile, level: level),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: unlocked ? 1 : 0.5,
        child: ComicPanel(
          color: level.isGuardian
              ? level.guardian.color
              : (unlocked ? level.habitat.color : Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.isGuardian
                    ? level.guardian.emoji
                    : (unlocked ? '${level.number}' : '🔒'),
                style: TextStyle(
                  fontSize: level.isGuardian ? 36 : 28,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              if (unlocked) ...[
                const SizedBox(height: 4),
                StarRow(earned: stars, size: 17),
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
          if (!alignLeft) const _Dots(),
          node,
          if (alignLeft) const _Dots(),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      child: Icon(Icons.more_horiz_rounded, color: AppTheme.ink),
    );
  }
}
