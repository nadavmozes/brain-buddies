import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/trail_map.dart';
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
    final s = context.l10n;
    final label = context.tr('ch.world.label', world.name, world.label);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.trailTitle(world.emoji, label),
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
          child: TrailMapView(
            listenable: state,
            pathColor: world.color,
            nodes: [
              for (final level in trail.levels) _nodeFor(context, level),
            ],
          ),
        ),
      ),
    );
  }

  TrailNodeData _nodeFor(BuildContext context, ClockLevel level) {
    final unlocked = state.isLevelUnlocked(level);
    final s = context.l10n;
    final title = level.isBoss ? s.guardian : s.stopN(level.number);
    return TrailNodeData(
      label: level.isBoss ? level.guardian.emoji : '${level.number}',
      title: title,
      color: level.isBoss ? const Color(0xFF5C6BC0) : level.world.color,
      unlocked: unlocked,
      stars: state.stars(level.id),
      isBoss: level.isBoss,
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
    );
  }
}
