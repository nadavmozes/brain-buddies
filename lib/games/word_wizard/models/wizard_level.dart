import 'package:flutter/material.dart';

/// The spellbook chapters (worlds) in Word Wizard. Each chapter uses a harder
/// word pool and a higher base difficulty.
enum WizardChapter {
  sprout, // easy words
  spark, // medium words
  storm, // hard words
}

extension WizardChapterInfo on WizardChapter {
  String get label {
    switch (this) {
      case WizardChapter.sprout:
        return 'Sprout';
      case WizardChapter.spark:
        return 'Spark';
      case WizardChapter.storm:
        return 'Storm';
    }
  }

  String get subtitle {
    switch (this) {
      case WizardChapter.sprout:
        return 'Short and simple starter spells.';
      case WizardChapter.spark:
        return 'Longer words and trickier letters.';
      case WizardChapter.storm:
        return 'The hardest words and spellings.';
    }
  }

  String get emoji {
    switch (this) {
      case WizardChapter.sprout:
        return '🌱';
      case WizardChapter.spark:
        return '✨';
      case WizardChapter.storm:
        return '⚡';
    }
  }

  Color get color {
    switch (this) {
      case WizardChapter.sprout:
        return const Color(0xFF66BB6A);
      case WizardChapter.spark:
        return const Color(0xFFEC407A);
      case WizardChapter.storm:
        return const Color(0xFF5E35B1);
    }
  }

  /// Base difficulty (0..1) for the chapter's word pool.
  double get baseDifficulty {
    switch (this) {
      case WizardChapter.sprout:
        return 0.1;
      case WizardChapter.spark:
        return 0.45;
      case WizardChapter.storm:
        return 0.75;
    }
  }
}

/// The final challenge is guarded by a "Spell Master" boss per chapter.
class SpellBoss {
  const SpellBoss({required this.name, required this.emoji});

  final String name;
  final String emoji;
}

class SpellBosses {
  SpellBosses._();

  static const Map<WizardChapter, SpellBoss> _byChapter = {
    WizardChapter.sprout: SpellBoss(name: 'Owlbert', emoji: '🦉'),
    WizardChapter.spark: SpellBoss(name: 'Foxfire', emoji: '🦊'),
    WizardChapter.storm: SpellBoss(name: 'Grand Mage', emoji: '🧙'),
  };

  static SpellBoss forChapter(WizardChapter c) => _byChapter[c]!;
}

/// A single lesson stop on a chapter's spellbook path.
class WizardLevel {
  const WizardLevel({
    required this.chapter,
    required this.index,
    required this.isBoss,
  });

  final WizardChapter chapter;
  final int index;
  final bool isBoss;

  int get number => index + 1;
  String get id => '${chapter.name}_$index';
  int get questionCount => isBoss ? 8 : 5;
  String get title => isBoss ? 'Spell Master' : 'Lesson $number';
  SpellBoss get boss => SpellBosses.forChapter(chapter);

  /// Per-level difficulty: chapter base plus a ramp along the path.
  double difficulty(int levelsPerChapter) {
    final ramp = index / (levelsPerChapter - 1) * 0.25;
    return (chapter.baseDifficulty + ramp).clamp(0.0, 1.0);
  }
}

/// A chapter's ordered list of lessons.
class WizardPath {
  WizardPath({required this.chapter, required this.levels});
  final WizardChapter chapter;
  final List<WizardLevel> levels;
  int get length => levels.length;
}

/// Builds the fixed spellbook layout: each chapter is a path of lessons ending
/// in a Spell Master boss.
class WizardMap {
  WizardMap._();

  static const int levelsPerChapter = 5; // 4 lessons + 1 boss

  static final Map<WizardChapter, WizardPath> paths = {
    for (final c in WizardChapter.values)
      c: WizardPath(
        chapter: c,
        levels: List.generate(
          levelsPerChapter,
          (i) => WizardLevel(
            chapter: c,
            index: i,
            isBoss: i == levelsPerChapter - 1,
          ),
        ),
      ),
  };

  static WizardPath path(WizardChapter c) => paths[c]!;

  static List<WizardLevel> get allLevels =>
      [for (final c in WizardChapter.values) ...path(c).levels];
}
