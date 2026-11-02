// Engagement Phase 4 unit tests: per-game MASTERY tier helper + cache, the
// daily surprise CHEST day-gate + fixed reward, the WHAT'S-NEW seen-per-day
// flag, and reset() clearing every new key.
//
// Day-gated getters read DateTime.now() internally, so seeds are expressed
// RELATIVE to now (today / yesterday).

import 'package:brain_buddies/core/models/game_catalog.dart';
import 'package:brain_buddies/core/models/mastery.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/games/memory_match/models/memory_level.dart';
import 'package:brain_buddies/games/memory_match/services/memory_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mastery tier helper (boundaries)', () {
    test('empty list -> none', () {
      expect(masteryTierForStars(const []), MasteryTier.none);
      expect(masteryTierForStars(const []).rank, 0);
    });

    test('one level missing a star -> none', () {
      expect(masteryTierForStars(const [3, 3, 0, 3]), MasteryTier.none);
    });

    test('all cleared but < 50% at 3 stars -> bronze', () {
      // 1 of 4 at three stars = 25% < 50%.
      expect(masteryTierForStars(const [3, 1, 1, 1]), MasteryTier.bronze);
      expect(MasteryTier.bronze.rank, 1);
    });

    test('exactly 50% at 3 stars -> silver', () {
      // 2 of 4 at three stars = 50%.
      expect(masteryTierForStars(const [3, 3, 1, 2]), MasteryTier.silver);
      expect(MasteryTier.silver.rank, 2);
    });

    test('100% at 3 stars -> gold', () {
      expect(masteryTierForStars(const [3, 3, 3]), MasteryTier.gold);
      expect(MasteryTier.gold.rank, 3);
    });

    test('fromRank clamps and maps', () {
      expect(MasteryTier.fromRank(0), MasteryTier.none);
      expect(MasteryTier.fromRank(1), MasteryTier.bronze);
      expect(MasteryTier.fromRank(2), MasteryTier.silver);
      expect(MasteryTier.fromRank(3), MasteryTier.gold);
      expect(MasteryTier.fromRank(99), MasteryTier.gold);
      expect(MasteryTier.fromRank(-5), MasteryTier.none);
    });
  });

  group('mastery cache', () {
    test('setMasteryTier/masteryTier round-trip + persist', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.masteryTier(GameCatalog.memoryMatch.id), 0);
      await profile.setMasteryTier(GameCatalog.memoryMatch.id, 2);
      expect(profile.masteryTier(GameCatalog.memoryMatch.id), 2);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('profile_mastery_memory_match'), 2);

      // Persisted across a reload.
      final reloaded = PlayerProfile();
      await reloaded.load();
      expect(reloaded.masteryTier(GameCatalog.memoryMatch.id), 2);
    });

    test('a game completeLevel updates the cached tier to gold', () async {
      // Seed every Memory level at 3 stars EXCEPT one (animals_0), so after
      // clearing that last one with a 3-star (no-wrong-flips) run every level
      // is at 3 stars and the tier becomes gold.
      final seed = <String, Object>{};
      for (final lvl in MemoryMap.allLevels) {
        if (lvl.id == 'animals_0') continue;
        seed['memory_level_${lvl.id}'] = 3;
      }
      SharedPreferences.setMockInitialValues(seed);

      final profile = PlayerProfile();
      await profile.load();
      expect(profile.masteryTier(GameCatalog.memoryMatch.id), 0,
          reason: 'cache is empty until a round updates it');

      final state = MemoryState();
      await state.load();

      final level = MemoryMap.allLevels.firstWhere((l) => l.id == 'animals_0');
      await state.completeLevel(
        profile: profile,
        level: level,
        wrongFlips: 0, // -> 3 stars
        elapsedSeconds: 10,
      );

      expect(profile.masteryTier(GameCatalog.memoryMatch.id), 3,
          reason: 'all levels now at 3 stars -> gold');
    });
  });

  group('daily surprise chest', () {
    test('a fresh profile can open and gets a valid fixed, non-empty reward',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.canOpenChest, isTrue);

      final reward = await profile.openChest();
      expect(reward, isNotNull);
      // Never empty: at least coins or treats.
      expect(reward!.coins > 0 || reward.treats > 0, isTrue);
      // Opening stamps today -> cannot open again.
      expect(profile.canOpenChest, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profile_chest_day'), _dayKey(DateTime.now()));
    });

    test('a second open the same day returns null and grants nothing',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      final first = await profile.openChest();
      expect(first, isNotNull);
      final coinsAfter = profile.coins;
      final treatsAfter = profile.petTreats;

      final second = await profile.openChest();
      expect(second, isNull);
      expect(profile.coins, coinsAfter);
      expect(profile.petTreats, treatsAfter);
    });

    test('canOpenChest flips true again on a new day', () async {
      final yesterday =
          _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'profile_chest_day': yesterday,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.canOpenChest, isTrue);
    });

    test('the reward is deterministic for a given day', () async {
      // Two fresh profiles opened on the same day must receive identical
      // rewards (coins + treats), proving the pick is day-deterministic.
      SharedPreferences.setMockInitialValues({});
      final a = PlayerProfile();
      await a.load();
      final ra = await a.openChest();

      SharedPreferences.setMockInitialValues({});
      final b = PlayerProfile();
      await b.load();
      final rb = await b.openChest();

      expect(ra, isNotNull);
      expect(rb, isNotNull);
      expect(ra!.coins, rb!.coins);
      expect(ra.treats, rb.treats);
    });
  });

  group("what's-new seen flag", () {
    test('fresh profile has not seen it today; flags read individually',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.whatsNewSeenToday, isFalse);
      // The hub builds its items from these live flags.
      expect(profile.canClaimDailyLogin, isTrue);
      expect(profile.canClaimDailyTreat, isTrue);
      expect(profile.canOpenChest, isTrue);
      expect(profile.hasClaimableMission, isFalse);
    });

    test('markWhatsNewSeen sets the flag for today and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      await profile.markWhatsNewSeen();
      expect(profile.whatsNewSeenToday, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profile_whatsnew_seen_day'),
          _dayKey(DateTime.now()));
    });

    test('a stale seen-day from yesterday resets today', () async {
      final yesterday =
          _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'profile_whatsnew_seen_day': yesterday,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.whatsNewSeenToday, isFalse);
    });
  });

  group('persistence + reset', () {
    test('reset() removes every new Phase 4 key', () async {
      SharedPreferences.setMockInitialValues({
        'profile_mastery_number_quest': 3,
        'profile_mastery_shape_safari': 2,
        'profile_mastery_word_wizard': 1,
        'profile_mastery_clock_hero': 3,
        'profile_mastery_money_math': 2,
        'profile_mastery_memory_match': 1,
        'profile_chest_day': '2020-01-01',
        'profile_whatsnew_seen_day': '2020-01-01',
      });
      final profile = PlayerProfile();
      await profile.load();

      await profile.reset();

      final prefs = await SharedPreferences.getInstance();
      for (final g in GameCatalog.all) {
        expect(prefs.get('profile_mastery_${g.id}'), isNull,
            reason: 'mastery for ${g.id} should be cleared');
        expect(profile.masteryTier(g.id), 0);
      }
      expect(prefs.get('profile_chest_day'), isNull);
      expect(prefs.get('profile_whatsnew_seen_day'), isNull);
      // In-memory getters back to defaults.
      expect(profile.canOpenChest, isTrue);
      expect(profile.whatsNewSeenToday, isFalse);
    });
  });
}
