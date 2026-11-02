// FEAT-003: finishing the off-map daily challenge must NOT touch per-game
// progression. For each wired game we snapshot totalStars / overallFastest /
// mastery tier, run completeLevel on dailyLevel() with isDaily:true (a strong,
// fast, perfect round), and assert: stars(level.id)==0, totalStars unchanged,
// overallFastest unchanged, and the shared mastery tier unchanged — while the
// shared coin balance DID increase (coins + onRoundFinished still run).

import 'package:brain_buddies/core/models/game_catalog.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PlayerProfile> freshProfile() async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();
    return profile;
  }

  test('shape_safari daily leaves progression untouched, coins rise', () async {
    final profile = await freshProfile();
    final state = SafariState();
    await state.load();
    final level = SafariMap.dailyLevel();

    final starsBefore = state.totalStars;
    final fastestBefore = state.overallFastest;
    final tierBefore = profile.masteryTier(GameCatalog.shapeSafari.id);
    final coinsBefore = profile.coins;

    await state.completeLevel(
      profile: profile,
      level: level,
      correct: 8,
      total: 8,
      guardianBefriended: false,
      elapsedSeconds: 5,
      isDaily: true,
    );

    expect(state.stars(level.id), 0);
    expect(state.totalStars, starsBefore);
    expect(state.overallFastest, fastestBefore);
    expect(profile.masteryTier(GameCatalog.shapeSafari.id), tierBefore);
    expect(profile.coins, greaterThan(coinsBefore));
  });

  test('word_wizard daily leaves progression untouched, coins rise', () async {
    final profile = await freshProfile();
    final state = WizardState();
    await state.load();
    final level = WizardMap.dailyLevel();

    final starsBefore = state.totalStars;
    final fastestBefore = state.overallFastest;
    final tierBefore = profile.masteryTier(GameCatalog.wordWizard.id);
    final coinsBefore = profile.coins;

    await state.completeLevel(
      profile: profile,
      level: level,
      correct: 100,
      total: 100,
      elapsedSeconds: 5,
      isDaily: true,
    );

    expect(state.stars(level.id), 0);
    expect(state.totalStars, starsBefore);
    expect(state.overallFastest, fastestBefore);
    expect(profile.masteryTier(GameCatalog.wordWizard.id), tierBefore);
    expect(profile.coins, greaterThan(coinsBefore));
  });

  test('clock_hero daily leaves progression untouched, coins rise', () async {
    final profile = await freshProfile();
    final state = ClockState();
    await state.load();
    final level = ClockMap.dailyLevel();

    final starsBefore = state.totalStars;
    final fastestBefore = state.overallFastest;
    final tierBefore = profile.masteryTier(GameCatalog.clockHero.id);
    final coinsBefore = profile.coins;

    await state.completeLevel(
      profile: profile,
      level: level,
      correct: 100,
      total: 100,
      elapsedSeconds: 5,
      isDaily: true,
    );

    expect(state.stars(level.id), 0);
    expect(state.totalStars, starsBefore);
    expect(state.overallFastest, fastestBefore);
    expect(profile.masteryTier(GameCatalog.clockHero.id), tierBefore);
    expect(profile.coins, greaterThan(coinsBefore));
  });

  test('money_math daily leaves progression untouched, coins rise', () async {
    final profile = await freshProfile();
    final state = MoneyState();
    await state.load();
    final level = MoneyMap.dailyLevel();

    final starsBefore = state.totalStars;
    final fastestBefore = state.overallFastest;
    final tierBefore = profile.masteryTier(GameCatalog.moneyMath.id);
    final coinsBefore = profile.coins;

    await state.completeLevel(
      profile: profile,
      level: level,
      correct: 100,
      total: 100,
      elapsedSeconds: 5,
      isDaily: true,
    );

    expect(state.stars(level.id), 0);
    expect(state.totalStars, starsBefore);
    expect(state.overallFastest, fastestBefore);
    expect(profile.masteryTier(GameCatalog.moneyMath.id), tierBefore);
    expect(profile.coins, greaterThan(coinsBefore));
  });

  test('memory_match daily leaves progression untouched, coins rise', () async {
    final profile = await freshProfile();
    final state = MemoryState();
    await state.load();
    final level = MemoryMap.dailyLevel();

    final starsBefore = state.totalStars;
    final fastestBefore = state.overallFastest;
    final tierBefore = profile.masteryTier(GameCatalog.memoryMatch.id);
    final coinsBefore = profile.coins;

    await state.completeLevel(
      profile: profile,
      level: level,
      wrongFlips: 0, // perfect -> 3 stars if it were on-map
      elapsedSeconds: 5,
      isDaily: true,
    );

    expect(state.stars(level.id), 0);
    expect(state.totalStars, starsBefore);
    expect(state.overallFastest, fastestBefore);
    expect(profile.masteryTier(GameCatalog.memoryMatch.id), tierBefore);
    expect(profile.coins, greaterThan(coinsBefore));
  });

  // Number Quest's daily behavior is preserved EXACTLY as it shipped: its
  // off-map daily still guards fastest-time + mastery (so the tier never
  // shifts), but — unlike the five GameProgressStore games — it was never
  // given an isDaily star/best-score skip. Assert only the invariants that
  // hold for NQ: the off-map id never affects unlock order (its id is absent
  // from allLevels) and mastery stays put, while coins still rise.
  test('number_quest daily preserves mastery + off-map id, coins rise',
      () async {
    final profile = await freshProfile();
    final state = GameState();
    await state.load();
    final level = WorldMap.dailyLevel();

    final tierBefore = profile.masteryTier(GameCatalog.numberQuest.id);
    final coinsBefore = profile.coins;

    await state.completeLevel(
      profile: profile,
      level: level,
      correct: 8,
      total: 8,
      roundScore: 80,
      bestAnswerStreak: 8,
      bossDefeated: false,
      elapsedSeconds: 5,
    );

    // The daily id is off-map, so it can never gate an on-map level's unlock.
    expect(WorldMap.allLevels.map((l) => l.id), isNot(contains(level.id)));
    // NQ's mastery tier folds over on-map levels only, so it is untouched.
    expect(profile.masteryTier(GameCatalog.numberQuest.id), tierBefore);
    // Fastest is guarded for off-map ids, so no record was set.
    expect(state.fastestSeconds(level.id), 0);
    expect(profile.coins, greaterThan(coinsBefore));
  });
}
