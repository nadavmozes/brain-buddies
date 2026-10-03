import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/star_row.dart';
import '../models/time_world.dart';
import '../services/clock_state.dart';
import 'clock_game_screen.dart';

/// A winding path of clock stops for one time-of-day world, ending in a
/// friendly guardian.
class ClockTrailScreen extends StatelessWidget {
  const ClockTrailScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.world,
  });

  final ClockState state;
  final PlayerProfile profile;
  final TimeWorld world;

  @override
  Widget build(BuildContext context) {
    final trail = ClockMap.trail(world);
    return Scaffold(
      appBar: AppBar(
        title: Text('${world.emoji} ${world.label} Trail',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [world.color.withOpacity(0.35), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: state,
            builder: (context, _) => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24),
              itemCount: trail.length,
              itemBuilder: (context, i) => _StopNode(
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

class _StopNode extends StatelessWidget {
  const _StopNode({
    required this.state,
    required this.profile,
    required this.level,
    required this.alignLeft,
  });

  final ClockState state;
  final PlayerProfile profile;
  final ClockLevel level;
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
                  builder: (_) => ClockGameScreen(
                      state: state, profile: profile, level: level),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: unlocked ? 1 : 0.5,
        child: ComicPanel(
          color: level.isBoss
              ? const Color(0xFF5C6BC0)
              : (unlocked ? level.world.color : Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.isBoss
                    ? level.guardian.emoji
                    : (unlocked ? '${level.number}' : '🔒'),
                style: TextStyle(
                  fontSize: level.isBoss ? 34 : 28,
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
