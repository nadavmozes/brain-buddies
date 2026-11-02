// Locks in the Engagement Phase 1 additions to PlayerProfile: the daily login
// reward cycle, the play-all-6 bonus, and the streak-freeze / comeback-gift
// handling layered onto recordPlayDay.
//
// recordPlayDay()/the day-gated getters read DateTime.now() internally, so
// seeds are expressed RELATIVE to now (today / yesterday / two-days-ago).

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

    test('day-7 special grants a streak freeze and wraps the cycle', () async {
      // Seed at cycle index 6 (the day-7 special box), claimable.
      SharedPreferences.setMockInitialValues({
        'profile_login_cycle': 6,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.todaysLoginReward.kind, DailyRewardKind.special);
      expect(profile.streakFreezes, 0);

      final startCoins = profile.coins;
      final reward = await profile.claimDailyLogin();
      expect(reward!.kind, DailyRewardKind.special);
      // Special pays 50 coins and grants one freeze.
      expect(profile.coins, startCoins + 50);
      expect(profile.streakFreezes, 1);
      // Cycle wraps back to 0.
      expect(profile.loginCycleIndex, 0);
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
  });
}
