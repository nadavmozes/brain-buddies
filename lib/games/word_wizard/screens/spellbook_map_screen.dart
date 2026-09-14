import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/star_row.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${chapter.emoji} ${chapter.label} Chapter',
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
          child: AnimatedBuilder(
            animation: state,
            builder: (context, _) => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24),
              itemCount: path.length,
              itemBuilder: (context, i) => _LessonNode(
                state: state,
                profile: profile,
                level: path.levels[i],
                alignLeft: i.isEven,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.state,
    required this.profile,
    required this.level,
    required this.alignLeft,
  });

  final WizardState state;
  final PlayerProfile profile;
  final WizardLevel level;
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
                  builder: (_) => WizardGameScreen(
                      state: state, profile: profile, level: level),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: unlocked ? 1 : 0.5,
        child: ComicPanel(
          color: level.isBoss
              ? const Color(0xFF5E35B1)
              : (unlocked ? level.chapter.color : Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.isBoss
                    ? level.boss.emoji
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
