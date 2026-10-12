import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/trail_map.dart';
import '../models/level.dart';
import '../services/game_state.dart';
import 'game_screen.dart';

/// A winding-path trail for the Times Tables campaign. Mirrors
/// [LevelMapScreen] but walks [TimesTablesMap.allLevels] and keeps the three
/// difficulty worlds untouched.
class TimesTablesMapScreen extends StatelessWidget {
  const TimesTablesMapScreen({
    super.key,
    required this.state,
    required this.profile,
  });

  final GameState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final label = s.nqTimesTablesLabel;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.worldTitle(TimesTablesMap.emoji, label),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TimesTablesMap.color.withOpacity(0.35), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: TrailMapView(
            listenable: state,
            pathColor: TimesTablesMap.color,
            nodes: [
              for (final level in TimesTablesMap.allLevels)
                _nodeFor(context, level),
            ],
          ),
        ),
      ),
    );
  }

  TrailNodeData _nodeFor(BuildContext context, GameLevel level) {
    final unlocked = state.isLevelUnlocked(level);
    final s = context.l10n;
    final title = level.isBoss ? s.guardian : s.levelN(level.number);
    return TrailNodeData(
      label: level.isBoss ? level.boss.emoji : '${level.number}',
      title: title,
      color: level.isBoss ? TimesTablesMap.color : level.worldColor,
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
