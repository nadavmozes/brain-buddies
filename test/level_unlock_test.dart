// Locks in the level-unlock gate shared across all games: the first level in
// play order is always open, and level N stays locked until level N-1 has at
// least one star. Covers the five GameProgressStore siblings via a single
// parameterized case, plus Number Quest's standalone GameState.

import 'package:brain_buddies/core/services/game_progress_store.dart';
import 'package:brain_buddies/games/clock_hero/models/time_world.dart';
import 'package:brain_buddies/games/clock_hero/services/clock_state.dart';
import 'package:brain_buddies/games/memory_match/models/memory_level.dart';
import 'package:brain_buddies/games/memory_match/services/memory_state.dart';
import 'package:brain_buddies/games/money_math/models/money_level.dart';
import 'package:brain_buddies/games/money_math/services/money_state.dart';
import 'package:brain_buddies/games/number_quest/models/level.dart';
import 'package:brain_buddies/games/number_quest/services/game_state.dart';
import 'package:brain_buddies/games/shape_safari/models/safari_level.dart';
import 'package:brain_buddies/games/shape_safari/services/safari_state.dart';
import 'package:brain_buddies/games/word_wizard/models/wizard_level.dart';
import 'package:brain_buddies/games/word_wizard/services/wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One sibling-store game under test.
class _StoreCase {
  _StoreCase({
    required this.name,
    required this.prefix,
    required this.makeStore,
    required this.levelIds,
  });

  final String name;
  final String prefix;
  final GameProgressStore Function() makeStore;
  final List<String> levelIds;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cases = <_StoreCase>[
    _StoreCase(
      name: 'Shape Safari',
      prefix: 'safari',
      makeStore: SafariState.new,
      levelIds: SafariMap.allLevels.map((l) => l.id).toList(),
    ),
    _StoreCase(
      name: 'Word Wizard',
      prefix: 'wizard',
      makeStore: WizardState.new,
      levelIds: WizardMap.allLevels.map((l) => l.id).toList(),
    ),
    _StoreCase(
      name: 'Clock Hero',
      prefix: 'clock',
      makeStore: ClockState.new,
      levelIds: ClockMap.allLevels.map((l) => l.id).toList(),
    ),
    _StoreCase(
      name: 'Money Math',
      prefix: 'money',
      makeStore: MoneyState.new,
      levelIds: MoneyMap.allLevels.map((l) => l.id).toList(),
    ),
    _StoreCase(
      name: 'Memory Match',
      prefix: 'memory',
      makeStore: MemoryState.new,
      levelIds: MemoryMap.allLevels.map((l) => l.id).toList(),
    ),
  ];

  for (final c in cases) {
    test('${c.name}: first level open, later levels gated by prior star',
        () async {
      final first = c.levelIds.first;
      final second = c.levelIds[1];
      final third = c.levelIds[2];

      // With no stars at all, only the first stop is unlocked.
      SharedPreferences.setMockInitialValues({});
      final fresh = c.makeStore();
      await fresh.load();
      expect(fresh.isLevelUnlockedById(first), isTrue,
          reason: 'first level is always open');
      expect(fresh.isLevelUnlockedById(second), isFalse,
          reason: 'second stays locked until the first earns a star');
      expect(fresh.isLevelUnlockedById(third), isFalse);

      // Seed one star on the first level -> the second unlocks, the third not.
      SharedPreferences.setMockInitialValues({'${c.prefix}_level_$first': 1});
      final seeded = c.makeStore();
      await seeded.load();
      expect(seeded.isLevelUnlockedById(first), isTrue);
      expect(seeded.isLevelUnlockedById(second), isTrue);
      expect(seeded.isLevelUnlockedById(third), isFalse,
          reason: 'the third needs a star on the second');
    });
  }

  test('Number Quest: first level open, later levels gated by prior star',
      () async {
    final levels = WorldMap.allLevels;
    final first = levels.first;
    final second = levels[1];
    final third = levels[2];

    SharedPreferences.setMockInitialValues({});
    final fresh = GameState();
    await fresh.load();
    expect(fresh.isLevelUnlocked(first), isTrue);
    expect(fresh.isLevelUnlocked(second), isFalse);
    expect(fresh.isLevelUnlocked(third), isFalse);

    // Number Quest persists stars under the nq_ namespace.
    SharedPreferences.setMockInitialValues({'nq_level_${first.id}': 1});
    final seeded = GameState();
    await seeded.load();
    expect(seeded.isLevelUnlocked(first), isTrue);
    expect(seeded.isLevelUnlocked(second), isTrue);
    expect(seeded.isLevelUnlocked(third), isFalse);
  });
}
