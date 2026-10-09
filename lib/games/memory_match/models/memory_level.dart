import 'package:flutter/material.dart';

/// Memory Match worlds (card decks), each with a different theme + bigger grids.
enum MemoryWorld {
  animals,
  fruits,
  space,
}

extension MemoryWorldInfo on MemoryWorld {
  String get label {
    switch (this) {
      case MemoryWorld.animals:
        return 'Animals';
      case MemoryWorld.fruits:
        return 'Fruits';
      case MemoryWorld.space:
        return 'Space';
    }
  }

  String get subtitle {
    switch (this) {
      case MemoryWorld.animals:
        return 'Match the friendly animals.';
      case MemoryWorld.fruits:
        return 'Pair up tasty fruits.';
      case MemoryWorld.space:
        return 'Find matching space pairs.';
    }
  }

  String get emoji {
    switch (this) {
      case MemoryWorld.animals:
        return '🐾';
      case MemoryWorld.fruits:
        return '🍓';
      case MemoryWorld.space:
        return '🚀';
    }
  }

  Color get color {
    switch (this) {
      case MemoryWorld.animals:
        return const Color(0xFF66BB6A);
      case MemoryWorld.fruits:
        return const Color(0xFFEF5350);
      case MemoryWorld.space:
        return const Color(0xFF5C6BC0);
    }
  }

  /// The emoji deck this world draws its cards from.
  List<String> get deck {
    switch (this) {
      case MemoryWorld.animals:
        return const [
          '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
          '🐨', '🐯', '🦁', '🐷', '🐸', '🐵', '🐔', '🦉'
        ];
      case MemoryWorld.fruits:
        return const [
          '🍎', '🍌', '🍇', '🍓', '🍊', '🍉', '🍐', '🍑',
          '🍒', '🥝', '🍍', '🥭', '🫐', '🥥', '🍋', '🍈'
        ];
      case MemoryWorld.space:
        return const [
          '🚀', '🛸', '⭐', '🌙', '☄️', '🪐', '🌍', '👽',
          '🌟', '🔭', '🛰️', '☀️', '🌌', '👾', '🌠', '🧑‍🚀'
        ];
    }
  }
}

/// The guardian at the end of each world's trail.
class MemoryGuardian {
  const MemoryGuardian({required this.name, required this.emoji});
  final String name;
  final String emoji;
}

class MemoryGuardians {
  MemoryGuardians._();

  static const Map<MemoryWorld, MemoryGuardian> _byWorld = {
    MemoryWorld.animals: MemoryGuardian(name: 'Ellie Elephant', emoji: '🐘'),
    MemoryWorld.fruits: MemoryGuardian(name: 'Captain Melon', emoji: '🍉'),
    MemoryWorld.space: MemoryGuardian(name: 'Comet King', emoji: '☄️'),
  };

  static MemoryGuardian forWorld(MemoryWorld w) => _byWorld[w]!;
}

/// A single stop on a world's memory trail. Each stop is a card grid; the grid
/// grows with the stop index, and the boss grid is the biggest.
class MemoryLevel {
  const MemoryLevel({
    required this.world,
    required this.index,
    required this.isBoss,
  });

  final MemoryWorld world;
  final int index;
  final bool isBoss;

  int get number => index + 1;
  String get id => '${world.name}_$index';
  String get title => isBoss ? 'Guardian' : 'Stop $number';
  MemoryGuardian get guardian => MemoryGuardians.forWorld(world);

  /// Number of matching PAIRS in this level's grid. Ramps 3 → 8 (boss).
  int get pairs {
    if (isBoss) return 8;
    return 3 + index; // stops: 3,4,5,6 pairs
  }

  /// Grid columns, chosen so the card grid stays tidy for the pair count.
  int get columns => (pairs * 2) <= 8 ? 3 : 4;
}

class MemoryTrail {
  MemoryTrail({required this.world, required this.levels});
  final MemoryWorld world;
  final List<MemoryLevel> levels;
  int get length => levels.length;
}

class MemoryMap {
  MemoryMap._();

  static const int levelsPerTrail = 5;

  static final Map<MemoryWorld, MemoryTrail> trails = {
    for (final w in MemoryWorld.values)
      w: MemoryTrail(
        world: w,
        levels: List.generate(
          levelsPerTrail,
          (i) => MemoryLevel(
            world: w,
            index: i,
            isBoss: i == levelsPerTrail - 1,
          ),
        ),
      ),
  };

  static MemoryTrail trail(MemoryWorld w) => trails[w]!;

  static List<MemoryLevel> get allLevels =>
      [for (final w in MemoryWorld.values) ...trail(w).levels];
}
