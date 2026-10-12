import 'package:flutter/material.dart';

import 'boss.dart';
import 'difficulty.dart';
import 'mult_level.dart';

/// A single level node on a world map.
class GameLevel {
  const GameLevel({
    required this.world,
    required this.index,
    required this.isBoss,
    this.mult,
    this.bossOverride,
    this.worldColorOverride,
    this.idOverride,
  });

  /// The difficulty tier this level belongs to (its "world"). For the Times
  /// Tables campaign this provides only a color/fallback; the real multiplication
  /// behavior comes from [mult].
  final Difficulty world;

  /// Zero-based position of the level within its world.
  final int index;

  /// Whether this is the boss node at the end of the world.
  final bool isBoss;

  /// Multiplication teaching spec, set only for Times Tables campaign levels.
  /// When non-null this level emits multiplication-only facts.
  final MultLevelSpec? mult;

  /// Overrides the boss creature (used by the Times Tables guardian).
  final Boss? bossOverride;

  /// Overrides the theme color (used by the Times Tables campaign).
  final Color? worldColorOverride;

  /// Overrides the persistence id. Used by the Times Tables campaign so its
  /// ids never collide with the three difficulty worlds' `<world>_<index>` ids.
  final String? idOverride;

  /// Human level number (1-based) within the world.
  int get number => index + 1;

  /// A globally-unique id used for persistence, e.g. "easy_3".
  String get id => idOverride ?? '${world.name}_$index';

  /// Questions in this level. Boss levels are a bit longer.
  int get questionCount => isBoss ? 8 : 6;

  String get title => isBoss ? 'BOSS' : 'Level $number';

  /// The boss creature guarding this world (used on boss levels).
  Boss get boss => bossOverride ?? Bosses.forWorld(world);

  /// Stable id for the boss name in the localized catalog (`nq.boss.name`).
  /// The three difficulty worlds key by their world name; the Times Tables
  /// campaign keys by `times`.
  String get bossId => bossOverride != null ? 'times' : world.name;

  /// Theme color for this level, honoring any campaign override.
  Color get worldColor => worldColorOverride ?? world.color;
}

/// A world is the ordered list of levels for one difficulty.
class GameWorld {
  GameWorld({required this.difficulty, required this.levels});

  final Difficulty difficulty;
  final List<GameLevel> levels;

  int get length => levels.length;
}

/// Builds the fixed map layout: each difficulty is a world with a path of
/// regular levels ending in a boss.
class WorldMap {
  WorldMap._();

  static const int levelsPerWorld = 6; // 5 regular + 1 boss

  static final Map<Difficulty, GameWorld> worlds = {
    for (final d in Difficulty.values)
      d: GameWorld(
        difficulty: d,
        levels: List.generate(
          levelsPerWorld,
          (i) => GameLevel(
            world: d,
            index: i,
            isBoss: i == levelsPerWorld - 1,
          ),
        ),
      ),
  };

  static GameWorld world(Difficulty d) => worlds[d]!;

  /// Every level across all worlds, in play order.
  static List<GameLevel> get allLevels =>
      [for (final d in Difficulty.values) ...world(d).levels];

  /// A special repeatable daily challenge. Its world rotates by day so the
  /// question mix changes, and it uses a stable id that never appears in the
  /// map (so it never affects unlock/star progression).
  static GameLevel dailyLevel([DateTime? now]) {
    final day = now ?? DateTime.now();
    final worldIndex = day.day % Difficulty.values.length;
    return GameLevel(
      world: Difficulty.values[worldIndex],
      index: 999,
      isBoss: false,
    );
  }
}

/// The Times Tables campaign: a dedicated multiplication world living alongside
/// the three difficulty worlds. It reuses [GameLevel] (via its optional
/// multiplication fields) and the shared trail/game/result screens, but has its
/// own ordered level list and its own unlock chain, and its ids use a dedicated
/// `mult_*` prefix so they can never collide with the three worlds.
class TimesTablesMap {
  TimesTablesMap._();

  /// Stable persistence id prefix for this campaign's levels.
  static const String idPrefix = 'mult';

  /// Comic theme color for the campaign (purple, matching the Times Guardian).
  static const Color color = Color(0xFF5E35B1);

  /// Emoji badge shown on the world-select tile.
  static const String emoji = '✖️';

  /// Number of levels in the campaign (5 teaching/recall + 1 boss).
  static const int levelCount = 6;

  static GameLevel _level(int index, MultLevelSpec spec, {bool isBoss = false}) {
    return GameLevel(
      // `world` only supplies a fallback; the real behavior comes from `mult`.
      world: Difficulty.expert,
      index: index,
      isBoss: isBoss,
      mult: spec,
      worldColorOverride: color,
      idOverride: '${idPrefix}_$index',
      bossOverride: isBoss ? Bosses.timesGuardian : null,
    );
  }

  /// All campaign levels in play order. Factors ramp from small (with the dot
  /// array) to larger plain recall, ending in the mixed-recall guardian.
  static final List<GameLevel> allLevels = [
    _level(0, const MultLevelSpec(minFactor: 1, maxFactor: 5, useArray: true)),
    _level(1, const MultLevelSpec(minFactor: 2, maxFactor: 6, useArray: true)),
    _level(2, const MultLevelSpec(minFactor: 3, maxFactor: 9, useArray: true)),
    _level(3, const MultLevelSpec(minFactor: 4, maxFactor: 10, useArray: false)),
    _level(4, const MultLevelSpec(minFactor: 6, maxFactor: 12, useArray: false)),
    _level(
      5,
      const MultLevelSpec(
        minFactor: 1,
        maxFactor: 12,
        useArray: false,
        isMixedRecall: true,
      ),
      isBoss: true,
    ),
  ];
}
