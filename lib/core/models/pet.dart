import 'package:flutter/material.dart';

/// A growth stage of the shared pet companion. The pet levels up as the child
/// earns XP across all games, hatching and growing through friendly stages.
class PetStage {
  const PetStage({
    required this.name,
    required this.emoji,
    required this.minLevel,
    required this.color,
  });

  final String name;
  final String emoji;
  final int minLevel;
  final Color color;
}

/// The pet companion: a single creature that grows through stages. Its level
/// is derived from accumulated pet XP (which mirrors coins/round rewards).
class Pet {
  Pet._();

  /// Growth stages in order (by the level at which they begin).
  static const List<PetStage> stages = [
    PetStage(name: 'Egg', emoji: '🥚', minLevel: 1, color: Color(0xFFBDBDBD)),
    PetStage(name: 'Hatchling', emoji: '🐣', minLevel: 3, color: Color(0xFFFFD54F)),
    PetStage(name: 'Chick', emoji: '🐥', minLevel: 6, color: Color(0xFFFFB300)),
    PetStage(name: 'Birdie', emoji: '🐦', minLevel: 10, color: Color(0xFF4FC3F7)),
    PetStage(name: 'Owl', emoji: '🦉', minLevel: 15, color: Color(0xFF8D6E63)),
    PetStage(name: 'Phoenix', emoji: '🦅', minLevel: 20, color: Color(0xFFEF5350)),
    PetStage(name: 'Dragon', emoji: '🐉', minLevel: 28, color: Color(0xFF66BB6A)),
  ];

  /// XP needed to reach [level] from level 1. Each level costs a bit more.
  static int xpForLevel(int level) {
    // 0 for level 1, then cumulative: 60, 130, 210, ... (60 + 10 per step).
    var total = 0;
    var step = 60;
    for (var l = 1; l < level; l++) {
      total += step;
      step += 10;
    }
    return total;
  }

  /// The level reached for a given [xp].
  static int levelForXp(int xp) {
    var level = 1;
    while (xp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// Progress (0..1) from the current level toward the next.
  static double progressForXp(int xp) {
    final level = levelForXp(xp);
    final start = xpForLevel(level);
    final next = xpForLevel(level + 1);
    if (next <= start) return 1;
    return ((xp - start) / (next - start)).clamp(0.0, 1.0);
  }

  /// The growth stage for a given level.
  static PetStage stageForLevel(int level) {
    var current = stages.first;
    for (final s in stages) {
      if (level >= s.minLevel) current = s;
    }
    return current;
  }
}
