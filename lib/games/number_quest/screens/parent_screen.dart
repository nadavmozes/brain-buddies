import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';
import '../models/skill.dart';
import '../services/game_state.dart';

/// A calm, parent-facing view of the child's math progress by skill.
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key, required this.state});

  final GameState state;

  Color _colorFor(int percent, int attempts) {
    if (attempts < 5) return Colors.grey;
    if (percent >= 90) return AppTheme.success;
    if (percent >= 70) return const Color(0xFF8BC34A);
    if (percent >= 50) return AppTheme.accent;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ComicPanel(
                color: AppTheme.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Hero Level', '${state.level}'),
                    _stat('Total Stars', '${state.totalStars}'),
                    _stat('Day Streak', '${state.dailyStreak}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Skills',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              for (final skill in Skill.values)
                _SkillRow(
                  skill: skill,
                  stat: state.skillStat(skill),
                  color: _colorFor(
                    state.skillStat(skill).percent,
                    state.skillStat(skill).attempts,
                  ),
                ),
              const SizedBox(height: 20),
              ComicPanel(
                color: AppTheme.paper,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tip for grown-ups',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                      _tip(state),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }

  String _tip(GameState state) {
    // Suggest the weakest practiced skill.
    Skill? weakest;
    var worst = 101;
    for (final s in Skill.values) {
      final stat = state.skillStat(s);
      if (stat.attempts >= 5 && stat.percent < worst) {
        worst = stat.percent;
        weakest = s;
      }
    }
    if (weakest == null) {
      return 'Keep playing a few quests so we can spot which skills need '
          'the most practice.';
    }
    return 'Right now ${weakest.label.toLowerCase()} could use the most '
        'practice. Try a few short sessions focused on that skill.';
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.skill,
    required this.stat,
    required this.color,
  });

  final Skill skill;
  final SkillStat stat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ComicPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(skill.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(skill.label,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text(stat.masteryLabel,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: stat.attempts == 0 ? 0 : stat.accuracy,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.attempts == 0
                        ? 'No questions yet'
                        : '${stat.correct} / ${stat.attempts} correct',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
