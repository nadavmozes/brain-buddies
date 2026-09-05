import 'guardian.dart';
import 'habitat.dart';

/// A single stop on a habitat trail.
class SafariLevel {
  const SafariLevel({
    required this.habitat,
    required this.index,
    required this.isGuardian,
  });

  /// The habitat (world) this stop belongs to.
  final Habitat habitat;

  /// Zero-based position within the habitat trail.
  final int index;

  /// Whether this is the guardian encounter at the end of the trail.
  final bool isGuardian;

  int get number => index + 1;

  /// Globally-unique persistence id, e.g. "jungle_2".
  String get id => '${habitat.name}_$index';

  /// Questions in this stop. Guardian encounters are a bit longer.
  int get questionCount => isGuardian ? 8 : 5;

  String get title => isGuardian ? 'Guardian' : 'Stop $number';

  /// The guardian for this habitat (used on guardian stops).
  SafariGuardian get guardian => Guardians.forHabitat(habitat);

  /// Per-level difficulty: habitat base plus a ramp along the trail.
  double difficulty(int levelsPerTrail) {
    final ramp = index / (levelsPerTrail - 1) * 0.3; // up to +0.3 by the end
    return (habitat.baseDifficulty + ramp).clamp(0.0, 1.0);
  }
}

/// A habitat's ordered trail of levels.
class SafariTrail {
  SafariTrail({required this.habitat, required this.levels});

  final Habitat habitat;
  final List<SafariLevel> levels;

  int get length => levels.length;
}

/// Builds the fixed trail layout: each habitat is a trail of stops ending in
/// a guardian encounter.
class SafariMap {
  SafariMap._();

  static const int levelsPerTrail = 5; // 4 stops + 1 guardian

  static final Map<Habitat, SafariTrail> trails = {
    for (final h in Habitat.values)
      h: SafariTrail(
        habitat: h,
        levels: List.generate(
          levelsPerTrail,
          (i) => SafariLevel(
            habitat: h,
            index: i,
            isGuardian: i == levelsPerTrail - 1,
          ),
        ),
      ),
  };

  static SafariTrail trail(Habitat h) => trails[h]!;

  /// Every level across all habitats, in play order.
  static List<SafariLevel> get allLevels =>
      [for (final h in Habitat.values) ...trail(h).levels];
}
