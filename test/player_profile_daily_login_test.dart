// Locks in the Engagement Phase 1 additions to PlayerProfile: the daily login
// reward cycle, the play-all-6 bonus, and the streak-freeze / comeback-gift
// handling layered onto recordPlayDay.
//
// recordPlayDay()/the day-gated getters read DateTime.now() internally, so
// seeds are expressed RELATIVE to now (today / yesterday / two-days-ago).

import 'package:brain_buddies/core/models/achievement.dart';
import 'package:brain_buddies/core/models/daily_reward.dart';
import 'package:brain_buddies/core/models/game_catalog.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('daily login reward', () {
    test('a fresh profile can claim today, advancing the cycle', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.canClaimDailyLogin, isTrue);
      expect(profile.loginCycleIndex, 0);
      final startCoins = profile.coins;

      final reward = await profile.claimDailyLogin();
      expect(reward, isNotNull);
      expect(reward!.dayIndex, 0);
      // Day 1 pays 5 coins.
      expect(profile.coins, startCoins + 5);
      // Cycle advanced and today stamped.
      expect(profile.loginCycleIndex, 1);
      expect(profile.canClaimDailyLogin, isFalse,
          reason: 'cannot claim twice the same day');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('profile_login_cycle'), 1);
      expect(prefs.getString('profile_login_last_claim'),
          _dayKey(DateTime.now()));
    });

    test('double-claim the same day pays nothing more', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      await profile.claimDailyLogin();
      final coinsAfterFirst = profile.coins;
      final second = await profile.claimDailyLogin();
      expect(second, isNull);
      expect(profile.coins, coinsAfterFirst);
    });

    test('canClaimDailyLogin flips true again on a new day', () async {
      // Seed a claim stamped yesterday at cycle index 2.
      final yesterday =
          _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'profile_login_last_claim': yesterday,
        'profile_login_cycle': 2,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.canClaimDailyLogin, isTrue);
      expect(profile.loginCycleIndex, 2);
      expect(profile.todaysLoginReward.dayIndex, 2);
    });

    test('day-7 special grants a streak freeze, pet XP, and wraps the cycle',
        () async {
      // Seed at cycle index 6 (the day-7 special box), claimable.
      SharedPreferences.setMockInitialValues({
        'profile_login_cycle': 6,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.todaysLoginReward.kind, DailyRewardKind.special);
      expect(profile.streakFreezes, 0);

      final startCoins = profile.coins;
      final startPetXp = profile.petXp;
      final reward = await profile.claimDailyLogin();
      expect(reward!.kind, DailyRewardKind.special);
      // Special pays 50 coins, 25 bonus pet XP, and grants one freeze.
      expect(profile.coins, startCoins + 50);
      expect(profile.petXp, startPetXp + 25, reason: 'day-7 pays bonus pet XP');
      expect(profile.streakFreezes, 1);
      // Cycle wraps back to 0.
      expect(profile.loginCycleIndex, 0);
    });

    test('day-7 freeze is capped at 1 when one is already held', () async {
      // Seed at the day-7 box AND already holding a freeze token.
      SharedPreferences.setMockInitialValues({
        'profile_login_cycle': 6,
        'profile_streak_freezes': 1,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.streakFreezes, 1);
      await profile.claimDailyLogin();
      // Still capped at a single token; the grant does not stack.
      expect(profile.streakFreezes, 1, reason: 'max 1 freeze held');
    });

    test('two concurrent (unawaited) claims pay and advance only once',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      final startCoins = profile.coins;
      // Fire both before awaiting either — the in-flight guard must let only
      // one through.
      final f1 = profile.claimDailyLogin();
      final f2 = profile.claimDailyLogin();
      final results = await Future.wait([f1, f2]);

      final nonNull = results.where((r) => r != null).toList();
      expect(nonNull.length, 1, reason: 'exactly one claim succeeds');
      // Only one payout (day 1 = 5 coins) and one cycle advance.
      expect(profile.coins, startCoins + 5);
      expect(profile.loginCycleIndex, 1);
      expect(profile.canClaimDailyLogin, isFalse);
    });
  });

  group('play-all-6 bonus', () {
    test('progress counts distinct games today and claim pays once', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      final total = GameCatalog.all.length;
      // Open each game once (plus a repeat to prove distinctness).
      for (final g in GameCatalog.all) {
        await profile.recordGamePlayed(g.id, total);
      }
      await profile.recordGamePlayed(GameCatalog.all.first.id, total);

      expect(profile.allSixProgress, total);
      expect(profile.canClaimAllSix, isTrue);

      final startCoins = profile.coins;
      final paid = await profile.claimAllSixBonus();
      expect(paid, 40);
      expect(profile.coins, startCoins + 40);
      expect(profile.canClaimAllSix, isFalse);

      // A second claim pays nothing more.
      expect(await profile.claimAllSixBonus(), 0);
      expect(profile.coins, startCoins + 40);
    });

    test('partial progress is not claimable', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      await profile.recordGamePlayed(GameCatalog.all.first.id,
          GameCatalog.all.length);
      expect(profile.allSixProgress, 1);
      expect(profile.canClaimAllSix, isFalse);
      expect(await profile.claimAllSixBonus(), 0);
    });

    test('a stale all-six set from yesterday rolls over to empty today',
        () async {
      // Seed a full set stamped yesterday; today it must start fresh at 0.
      final yesterday =
          _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'profile_allsix_day': yesterday,
        'profile_allsix_set': GameCatalog.all.map((g) => g.id).toList(),
      });
      final profile = PlayerProfile();
      await profile.load();

      // load() rolls the stale day over to an empty set.
      expect(profile.allSixProgress, 0);
      expect(profile.allSixPlayedToday, isEmpty);
      expect(profile.canClaimAllSix, isFalse);

      // Recording a game today starts a clean count at 1.
      await profile.recordGamePlayed(GameCatalog.all.first.id,
          GameCatalog.all.length);
      expect(profile.allSixProgress, 1);
    });
  });

  group('streak freeze + comeback gift (recordPlayDay)', () {
    test('consecutive day still increments (unchanged behavior)', () async {
      final yesterday =
          _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'profile_daily_streak': 4,
        'profile_last_day': yesterday,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(await profile.recordPlayDay(), 5);
      expect(profile.comebackGiftPending, isFalse);
    });

    test('a 2+ day gap WITHOUT a freeze resets to 1 and sets comeback',
        () async {
      final threeDaysAgo =
          _dayKey(DateTime.now().subtract(const Duration(days: 3)));
      SharedPreferences.setMockInitialValues({
        'profile_daily_streak': 9,
        'profile_last_day': threeDaysAgo,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(await profile.recordPlayDay(), 1);
      expect(profile.comebackGiftPending, isTrue,
          reason: 'a lost streak offers a comeback gift');

      // The comeback gift pays once then clears.
      final startCoins = profile.coins;
      expect(await profile.claimComebackGift(), 20);
      expect(profile.coins, startCoins + 20);
      expect(profile.comebackGiftPending, isFalse);
      expect(await profile.claimComebackGift(), 0);
    });

    test('a single missed day with a freeze KEEPS the streak', () async {
      final twoDaysAgo =
          _dayKey(DateTime.now().subtract(const Duration(days: 2)));
      SharedPreferences.setMockInitialValues({
        'profile_daily_streak': 6,
        'profile_last_day': twoDaysAgo,
        'profile_streak_freezes': 1,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.streakFreezes, 1);
      // One-day gap forgiven: streak advances as if yesterday was played.
      expect(await profile.recordPlayDay(), 7);
      expect(profile.streakFreezes, 0, reason: 'the freeze is consumed');
      expect(profile.comebackGiftPending, isFalse,
          reason: 'the streak was saved, so no comeback gift');
    });

    test('a freeze-saved jump from 6 to 7 still grants the 7-day achievement',
        () async {
      // A single missed day consumes the freeze and advances 6 -> 7, which
      // must still fire streak_3_days and streak_7_days exactly as the normal
      // consecutive-day path would.
      final twoDaysAgo =
          _dayKey(DateTime.now().subtract(const Duration(days: 2)));
      SharedPreferences.setMockInitialValues({
        'profile_daily_streak': 6,
        'profile_last_day': twoDaysAgo,
        'profile_streak_freezes': 1,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.hasAchievement(Achievements.streak7days.id), isFalse);
      expect(await profile.recordPlayDay(), 7);
      expect(profile.hasAchievement(Achievements.streak3days.id), isTrue);
      expect(profile.hasAchievement(Achievements.streak7days.id), isTrue);
    });

    test('a 2-day gap with NO freeze resets (freeze only covers one day)',
        () async {
      final twoDaysAgo =
          _dayKey(DateTime.now().subtract(const Duration(days: 2)));
      SharedPreferences.setMockInitialValues({
        'profile_daily_streak': 6,
        'profile_last_day': twoDaysAgo,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(await profile.recordPlayDay(), 1);
      expect(profile.comebackGiftPending, isTrue);
    });

    test('a fresh player first day sets no comeback gift', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      expect(await profile.recordPlayDay(), 1);
      expect(profile.comebackGiftPending, isFalse);
    });

    test('a pending comeback gift survives a reload', () async {
      // Persisted comeback state: a flag stored last session must still be
      // pending after a fresh load() so the hub card reappears.
      SharedPreferences.setMockInitialValues({
        'profile_comeback_pending': true,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.comebackGiftPending, isTrue);
      expect(await profile.claimComebackGift(), 20);
      expect(profile.comebackGiftPending, isFalse);

      // The cleared flag is persisted, so a reload stays clear.
      final reloaded = PlayerProfile();
      await reloaded.load();
      expect(reloaded.comebackGiftPending, isFalse);
    });
  });

  group('persistence + reset', () {
    // Every new engagement key must round-trip through shared_preferences and
    // be removed by reset().
    const newKeys = [
      'profile_login_last_claim',
      'profile_login_cycle',
      'profile_allsix_day',
      'profile_allsix_set',
      'profile_allsix_claimed',
      'profile_comeback_pending',
      'profile_streak_freezes',
    ];

    test('reset() removes every new engagement key', () async {
      // Seed all seven new keys with non-default values.
      SharedPreferences.setMockInitialValues({
        'profile_login_last_claim': '2020-01-01',
        'profile_login_cycle': 3,
        'profile_allsix_day': '2020-01-01',
        'profile_allsix_set': const ['a', 'b'],
        'profile_allsix_claimed': '2020-01-01',
        'profile_comeback_pending': true,
        'profile_streak_freezes': 1,
      });
      final profile = PlayerProfile();
      await profile.load();

      await profile.reset();

      final prefs = await SharedPreferences.getInstance();
      for (final k in newKeys) {
        expect(prefs.get(k), isNull, reason: '$k should be cleared by reset()');
      }
      // In-memory state is back to defaults too.
      expect(profile.loginCycleIndex, 0);
      expect(profile.canClaimDailyLogin, isTrue);
      expect(profile.allSixProgress, 0);
      expect(profile.comebackGiftPending, isFalse);
      expect(profile.streakFreezes, 0);
    });
  });
}
