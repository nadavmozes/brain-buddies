import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_panel.dart';
import '../models/skill.dart';
import '../services/game_state.dart';

/// A calm, parent-facing view of the child's math progress by skill.
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key, required this.state, required this.profile});

  final GameState state;
  final PlayerProfile profile;

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
        title: Text(context.l10n.progress,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
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
                    _stat(context.l10n.nqHeroLevel, '${state.level}'),
                    _stat(context.l10n.nqTotalStars, '${state.totalStars}'),
                    _stat(context.l10n.nqDayStreakLabel,
                        '${profile.dailyStreak}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(context.l10n.nqSkills,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
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
                    Text(context.l10n.nqGrownupTip,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                      _tip(context, state),
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

  String _tip(BuildContext context, GameState state) {
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
      return context.l10n.nqTipDefault;
    }
    return context.l10n.nqTipWeakest(
      context
          .tr('nq.skill.label', weakest.name, weakest.label)
          .toLowerCase(),
    );
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

  /// Localized mirror of [SkillStat.masteryLabel]'s thresholds. The model
  /// getter is kept as an English fallback and is not changed.
  String _mastery(BuildContext context, SkillStat stat) {
    final l = context.l10n;
    if (stat.attempts < 5) return l.masteryJustStarting;
    if (stat.percent >= 90) return l.masteryMastered;
    if (stat.percent >= 70) return l.masteryStrong;
    if (stat.percent >= 50) return l.masteryPracticing;
    return l.masteryNeedsPractice;
  }

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
                      Text(context.tr('nq.skill.label', skill.name, skill.label),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text(_mastery(context, stat),
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
                        ? context.l10n.nqNoQuestionsYet
                        : context.l10n
                            .correctOfTotal(stat.correct, stat.attempts),
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
