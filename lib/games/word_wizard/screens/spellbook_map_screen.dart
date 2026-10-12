import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/trail_map.dart';
import '../models/wizard_level.dart';
import '../services/wizard_state.dart';
import 'wizard_game_screen.dart';

/// A winding path of lessons for one chapter, ending in a Spell Master boss.
class SpellbookMapScreen extends StatelessWidget {
  const SpellbookMapScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.chapter,
  });

  final WizardState state;
  final PlayerProfile profile;
  final WizardChapter chapter;

  @override
  Widget build(BuildContext context) {
    final path = WizardMap.path(chapter);
    final s = context.l10n;
    final label = context.tr('ww.chapter.label', chapter.name, chapter.label);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.chapterTitle(chapter.emoji, label),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [chapter.color.withOpacity(0.35), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: TrailMapView(
            listenable: state,
            pathColor: chapter.color,
            nodes: [
              for (final level in path.levels) _nodeFor(context, level),
            ],
          ),
        ),
      ),
    );
  }

  TrailNodeData _nodeFor(BuildContext context, WizardLevel level) {
    final unlocked = state.isLevelUnlocked(level);
    final s = context.l10n;
    final title = level.isBoss ? s.spellMaster : s.lessonN(level.number);
    return TrailNodeData(
      label: level.isBoss ? level.boss.emoji : '${level.number}',
      title: title,
      color: level.isBoss ? const Color(0xFF5E35B1) : level.chapter.color,
      unlocked: unlocked,
      stars: state.stars(level.id),
      isBoss: level.isBoss,
      onTap: unlocked
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WizardGameScreen(
                      state: state, profile: profile, level: level),
                ),
              );
            }
          : null,
    );
  }
}
