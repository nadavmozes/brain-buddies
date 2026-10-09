import 'package:flutter/material.dart';

import '../core/models/pet.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/comic_panel.dart';

/// The hub-level pet companion screen. The pet grows through stages as the
/// child earns XP across all games.
class PetScreen extends StatelessWidget {
  const PetScreen({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Buddy',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.sky, AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: profile,
            builder: (context, _) {
              final level = profile.petLevel;
              final stage = profile.petStage;
              final nextStage = _nextStage(level);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Big pet display.
                    Container(
                      width: 180,
                      height: 180,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: stage.color.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.ink, width: 4),
                        boxShadow: AppTheme.comicShadow(offset: 5),
                      ),
                      child: Text(stage.emoji,
                          style: const TextStyle(fontSize: 96)),
                    ),
                    const SizedBox(height: 16),
                    ComicPanel(
                      color: stage.color,
                      child: Column(
                        children: [
                          Text(
                            stage.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: AppTheme.ink, offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                          Text(
                            'Level $level',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // XP progress to next level.
                    ComicPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Growth',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: profile.petProgress,
                              minHeight: 16,
                              backgroundColor: Colors.grey.shade200,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            nextStage == null
                                ? 'Your buddy is fully grown! 🎉'
                                : 'Keep playing to reach ${nextStage.name} '
                                    '${nextStage.emoji} at level ${nextStage.minLevel}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stage timeline.
                    ComicPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Growth Stages',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final s in Pet.stages)
                                _StageChip(
                                  stage: s,
                                  reached: level >= s.minLevel,
                                  current: s.name == stage.name,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your buddy grows as you earn stars and coins in any game.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PetStage? _nextStage(int level) {
    for (final s in Pet.stages) {
      if (s.minLevel > level) return s;
    }
    return null;
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.stage,
    required this.reached,
    required this.current,
  });

  final PetStage stage;
  final bool reached;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: reached ? 1 : 0.45,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: current ? AppTheme.accent : Colors.white,
          border: Border.all(
              color: current ? AppTheme.ink : Colors.grey, width: 2.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(reached ? stage.emoji : '🔒',
                style: const TextStyle(fontSize: 26)),
            Text('Lv ${stage.minLevel}',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
