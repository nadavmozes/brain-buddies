import 'package:flutter/material.dart';

import 'difficulty.dart';

/// A friendly boss creature that guards the end of a world.
class Boss {
  const Boss({
    required this.name,
    required this.emoji,
    required this.color,
    required this.taunt,
  });

  final String name;
  final String emoji;
  final Color color;

  /// A playful line shown when the battle starts.
  final String taunt;
}

/// One distinct boss per world. Kept kid-friendly (no scary faces).
class Bosses {
  Bosses._();

  static const Map<Difficulty, Boss> _byWorld = {
    Difficulty.easy: Boss(
      name: 'GulPuff',
      emoji: '🐡',
      color: Color(0xFF4CAF50),
      taunt: 'Can you add up faster than me?',
    ),
    Difficulty.intermediate: Boss(
      name: 'Octo',
      emoji: '🐙',
      color: Color(0xFFFF9800),
      taunt: 'Eight arms, lots of questions!',
    ),
    Difficulty.expert: Boss(
      name: 'Draco',
      emoji: '🐲',
      color: Color(0xFF7E57C2),
      taunt: 'Only true heroes beat a dragon!',
    ),
  };

  static Boss forWorld(Difficulty d) => _byWorld[d]!;
}
