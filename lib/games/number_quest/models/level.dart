import 'boss.dart';
import 'difficulty.dart';

/// A single level node on a world map.
class GameLevel {
  const GameLevel({
    required this.world,
    required this.index,
    required this.isBoss,
  });

  /// The difficulty tier this level belongs to (its "world").
  final Difficulty world;

  /// Zero-based position of the level within its world.
  final int index;

  /// Whether this is the boss node at the end of the world.
  final bool isBoss;

  /// Human level number (1-based) within the world.
  int get number => index + 1;

  /// A globally-unique id used for persistence, e.g. "easy_3".
  String get id => '${world.name}_$index';

  /// Questions in this level. Boss levels are a bit longer.
  int get questionCount => isBoss ? 8 : 6;

  String get title => isBoss ? 'BOSS' : 'Level $number';

  /// The boss creature guarding this world (used on boss levels).
  Boss get boss => Bosses.forWorld(world);
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
