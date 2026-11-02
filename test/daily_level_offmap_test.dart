// FEAT-003: the rotating daily challenge uses an OFF-MAP level per game.
// Each game's dailyLevel() must carry an id (index 999) that is NOT present in
// that game's allLevels, so the off-map round can never land in
// star/unlock/fastest/mastery progression (those fold over the whole map).

import 'package:brain_buddies/games/clock_hero/models/time_world.dart';
import 'package:brain_buddies/games/memory_match/models/memory_level.dart';
import 'package:brain_buddies/games/money_math/models/money_level.dart';
import 'package:brain_buddies/games/number_quest/models/level.dart';
import 'package:brain_buddies/games/shape_safari/models/safari_level.dart';
import 'package:brain_buddies/games/word_wizard/models/wizard_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Each entry: game label, the daily level's id, and the set of on-map ids.
  final cases = <(String, String, List<String>)>[
    (
      'number_quest',
      WorldMap.dailyLevel().id,
      WorldMap.allLevels.map((l) => l.id).toList(),
    ),
    (
      'shape_safari',
      SafariMap.dailyLevel().id,
      SafariMap.allLevels.map((l) => l.id).toList(),
    ),
    (
      'word_wizard',
      WizardMap.dailyLevel().id,
      WizardMap.allLevels.map((l) => l.id).toList(),
    ),
    (
      'clock_hero',
      ClockMap.dailyLevel().id,
      ClockMap.allLevels.map((l) => l.id).toList(),
    ),
    (
      'money_math',
      MoneyMap.dailyLevel().id,
      MoneyMap.allLevels.map((l) => l.id).toList(),
    ),
    (
      'memory_match',
      MemoryMap.dailyLevel().id,
      MemoryMap.allLevels.map((l) => l.id).toList(),
    ),
  ];

  for (final c in cases) {
    test('${c.$1} dailyLevel id "${c.$2}" is off-map (not in allLevels)', () {
      expect(c.$2, endsWith('_999'),
          reason: 'off-map daily uses the index-999 convention');
      expect(c.$3, isNot(contains(c.$2)),
          reason: 'the daily id must never appear in the on-map level list');
    });

    test('${c.$1} dailyLevel rotates its world by day', () {
      // Two days that fall in different modulo buckets must differ; spanning a
      // full set of consecutive days must touch more than one world.
      final ids = <String>{
        for (var day = 1; day <= 6; day++)
          // Use a fixed month so only the day drives the rotation.
          _dailyIdFor(c.$1, DateTime(2024, 6, day)),
      };
      expect(ids.length, greaterThan(1),
          reason: 'the daily world should change across days');
    });
  }
}

String _dailyIdFor(String game, DateTime d) {
  switch (game) {
    case 'number_quest':
      return WorldMap.dailyLevel(d).id;
    case 'shape_safari':
      return SafariMap.dailyLevel(d).id;
    case 'word_wizard':
      return WizardMap.dailyLevel(d).id;
    case 'clock_hero':
      return ClockMap.dailyLevel(d).id;
    case 'money_math':
      return MoneyMap.dailyLevel(d).id;
    case 'memory_match':
      return MemoryMap.dailyLevel(d).id;
    default:
      throw ArgumentError('unknown game $game');
  }
}
