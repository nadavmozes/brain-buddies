import 'package:brain_buddies/games/clock_hero/services/clock_state.dart';
import 'package:brain_buddies/games/memory_match/services/memory_state.dart';
import 'package:brain_buddies/games/money_math/services/money_state.dart';
import 'package:brain_buddies/games/number_quest/models/level.dart';
import 'package:brain_buddies/games/number_quest/models/skill.dart';
import 'package:brain_buddies/games/number_quest/services/game_state.dart';
import 'package:brain_buddies/games/shape_safari/models/safari_level.dart';
import 'package:brain_buddies/games/shape_safari/services/safari_state.dart';
import 'package:brain_buddies/games/word_wizard/models/wizard_level.dart';
import 'package:brain_buddies/games/word_wizard/services/wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Case A: refactored sibling stores read their legacy keys identically.
  test('sibling stores load legacy shared_preferences keys unchanged',
      () async {
    final safariFirst = SafariMap.allLevels.first.id;
    final safariGuardian = SafariMap.allLevels.last.id;
    final wizardFirst = WizardMap.allLevels.first.id;

    SharedPreferences.setMockInitialValues({
      'safari_level_$safariFirst': 2,
      'safari_fastest_$safariFirst': 10,
      'safari_sound': false,
      'safari_befriended': <String>[safariGuardian],
      'wizard_level_$wizardFirst': 3,
      'memory_sound': false,
    });

    final safari = SafariState();
    await safari.load();
    expect(safari.stars(safariFirst), 2);
    expect(safari.fastestSeconds(safariFirst), 10);
    expect(safari.soundOn, isFalse);
    expect(safari.guardianBefriended(safariGuardian), isTrue);

    final wizard = WizardState();
    await wizard.load();
    expect(wizard.stars(wizardFirst), 3);
    expect(wizard.soundOn, isTrue); // no wizard_sound set -> default true

    final memory = MemoryState();
    await memory.load();
    expect(memory.soundOn, isFalse);

    // Other sibling stores default cleanly with no keys present.
    final clock = ClockState();
    await clock.load();
    expect(clock.soundOn, isTrue);

    final money = MoneyState();
    await money.load();
    expect(money.soundOn, isTrue);
  });

  // Case B: Number Quest migrates its legacy bare keys to the nq_ namespace.
  test('Number Quest migrates legacy keys to nq_ without touching others',
      () async {
    final nqFirst = WorldMap.allLevels.first.id;

    SharedPreferences.setMockInitialValues({
      'xp': 100,
      'sound_on': false,
      'level_$nqFirst': 3,
      'fastest_$nqFirst': 12,
      'skill_addition_correct': 7,
      'skill_addition_attempts': 9,
      'safari_best': 5,
    });

    final game = GameState();
    await game.load();

    // In-memory values read correctly post-migration.
    expect(game.xp, 100);
    expect(game.soundOn, isFalse);
    expect(game.stars(nqFirst), 3);
    expect(game.fastestSeconds(nqFirst), 12);
    expect(game.skillStat(Skill.addition).correct, 7);
    expect(game.skillStat(Skill.addition).attempts, 9);

    final prefs = await SharedPreferences.getInstance();
    // New namespaced keys exist.
    expect(prefs.getInt('nq_xp'), 100);
    expect(prefs.getBool('nq_sound_on'), isFalse);
    expect(prefs.getInt('nq_level_$nqFirst'), 3);
    expect(prefs.getInt('nq_skill_addition_correct'), 7);
    // Old bare keys removed.
    expect(prefs.containsKey('xp'), isFalse);
    expect(prefs.containsKey('sound_on'), isFalse);
    expect(prefs.containsKey('level_$nqFirst'), isFalse);
    expect(prefs.containsKey('skill_addition_correct'), isFalse);
    // Unrelated store key untouched.
    expect(prefs.getInt('safari_best'), 5);
  });
}
