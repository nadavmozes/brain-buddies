import 'package:flutter/material.dart';

/// The three difficulty tiers, roughly mapped to grades 1-3.
enum Difficulty {
  easy,
  intermediate,
  expert,
}

extension DifficultyInfo on Difficulty {
  /// Display label shown on buttons and headers.
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.intermediate:
        return 'Intermediate';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  /// Kid-friendly subtitle describing the grade band.
  String get subtitle {
    switch (this) {
      case Difficulty.easy:
        return 'Grade 1 - Adding & taking away small numbers';
      case Difficulty.intermediate:
        return 'Grade 2 - Bigger sums and simple times tables';
      case Difficulty.expert:
        return 'Grade 3 - Multiplication, division & mixed quests';
    }
  }

  /// Emoji badge used in the comic-style cards.
  String get emoji {
    switch (this) {
      case Difficulty.easy:
        return '🌱';
      case Difficulty.intermediate:
        return '⭐';
      case Difficulty.expert:
        return '🔥';
    }
  }

  /// Theme color for each tier.
  Color get color {
    switch (this) {
      case Difficulty.easy:
        return const Color(0xFF4CAF50);
      case Difficulty.intermediate:
        return const Color(0xFFFF9800);
      case Difficulty.expert:
        return const Color(0xFFE53935);
    }
  }

  /// Persistence key used by the progress store.
  String get storageKey => 'difficulty_$name';

  /// Number of questions in a single adventure round.
  int get questionsPerRound => 10;
}
