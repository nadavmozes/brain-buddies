import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/trail_map.dart';
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
    final s = context.l10n;
    final habitatLabel =
        context.tr('ss.habitat.label', habitat.name, habitat.label);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.trailTitle(habitat.emoji, habitatLabel),
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
          child: TrailMapView(
            listenable: state,
            pathColor: habitat.color,
            nodes: [
              for (final level in trail.levels)
                _nodeFor(context, level),
            ],
          ),
        ),
      ),
    );
  }

  TrailNodeData _nodeFor(BuildContext context, SafariLevel level) {
    final unlocked = state.isLevelUnlocked(level);
    final s = context.l10n;
    final title = level.isGuardian ? s.guardian : s.stopN(level.number);
    return TrailNodeData(
      label: level.isGuardian ? level.guardian.emoji : '${level.number}',
      title: title,
      color: level.isGuardian ? level.guardian.color : level.habitat.color,
      unlocked: unlocked,
      stars: state.stars(level.id),
      isBoss: level.isGuardian,
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
    );
  }
}
