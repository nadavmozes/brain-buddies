// Deterministic unit tests for Engagement Phase 3 (pet treats, coin
// daily-double, weekly goal) on PlayerProfile. These seed shared_preferences
// with computed day/week keys to drive the once-per-day / once-per-week and
// rollover logic without depending on the real wall clock beyond "today".

import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _weekKeyNow() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return 'W${_dayKey(monday)}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = _dayKey(DateTime.now());
  final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));

  group('pet treats (P4)', () {
    test('claimDailyTreat grants exactly once per day, flips next day',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.canClaimDailyTreat, isTrue);
      expect(profile.petTreats, 0);

      final first = await profile.claimDailyTreat();
      expect(first, isTrue);
      expect(profile.petTreats, 1);
      expect(profile.canClaimDailyTreat, isFalse);

      // Second claim same day is a no-op.
      final second = await profile.claimDailyTreat();
      expect(second, isFalse);
      expect(profile.petTreats, 1);
    });

    test('a stale (yesterday) treat day lets the free treat be claimed again',
        () async {
      SharedPreferences.setMockInitialValues({
        'profile_daily_treat_day': yesterday,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.canClaimDailyTreat, isTrue);
      final granted = await profile.claimDailyTreat();
      expect(granted, isTrue);
      expect(profile.petTreats, 1);
    });

    test('feedPet spends one treat and adds the small XP; no-ops at 0 treats',
        () async {
      SharedPreferences.setMockInitialValues({'profile_pet_treats': 2});
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.petTreats, 2);
      final xpBefore = profile.petXp;

      final fed = await profile.feedPet();
      expect(fed, isTrue);
      expect(profile.petTreats, 1);
      expect(profile.petXp, xpBefore + 8); // _kTreatXp

      // Spend the last treat, then a further feed is a no-op.
      expect(await profile.feedPet(), isTrue);
      expect(profile.petTreats, 0);
      final xpAtZero = profile.petXp;
      expect(await profile.feedPet(), isFalse);
      expect(profile.petTreats, 0);
      expect(profile.petXp, xpAtZero); // unchanged
    });
  });

  group('onRoundFinished treat earn + coin daily-double (P4 / P10)', () {
    test('awards +1 treat only on bossBeaten or threeStars', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      // Plain round: no treat.
      await profile.onRoundFinished(
          correct: 3, coinsEarned: 5, threeStars: false, bossBeaten: false);
      expect(profile.petTreats, 0);

      // 3-star round: +1 treat.
      await profile.onRoundFinished(
          correct: 3, coinsEarned: 5, threeStars: true, bossBeaten: false);
      expect(profile.petTreats, 1);

      // Boss round: +1 treat.
      await profile.onRoundFinished(
          correct: 3, coinsEarned: 5, threeStars: false, bossBeaten: true);
      expect(profile.petTreats, 2);
    });

    test('first finished round of the day doubles (capped); second is normal',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      // First win today: games credit coinsEarned first, then onRoundFinished
      // credits the extra so the balance reflects the double (10 -> 20).
      await profile.addCoins(10);
      await profile.onRoundFinished(
          correct: 3, coinsEarned: 10, threeStars: false, bossBeaten: false);
      expect(profile.lastRoundWasDoubled, isTrue);
      expect(profile.lastRoundCoinsPaid, 20);
      expect(profile.coins, 20, reason: 'balance reflects the doubled payout');

      // Second win same day: not doubled, balance gains only the single amount.
      await profile.addCoins(10);
      await profile.onRoundFinished(
          correct: 3, coinsEarned: 10, threeStars: false, bossBeaten: false);
      expect(profile.lastRoundWasDoubled, isFalse);
      expect(profile.lastRoundCoinsPaid, 10);
      expect(profile.coins, 30, reason: 'second round pays normally');
    });

    test('daily-double payout is capped at 60', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      // 40 * 2 = 80 would exceed the cap -> clamped to 60. The game credited 40,
      // onRoundFinished credits the extra 20 so the balance lands on 60.
      await profile.addCoins(40);
      await profile.onRoundFinished(
          correct: 3, coinsEarned: 40, threeStars: false, bossBeaten: false);
      expect(profile.lastRoundWasDoubled, isTrue);
      expect(profile.lastRoundCoinsPaid, 60);
      expect(profile.coins, 60, reason: 'balance reflects the capped double');
    });

    test('already-doubled today (seeded) does not double again', () async {
      SharedPreferences.setMockInitialValues({'profile_double_day': today});
      final profile = PlayerProfile();
      await profile.load();

      await profile.addCoins(10);
      await profile.onRoundFinished(
          correct: 3, coinsEarned: 10, threeStars: false, bossBeaten: false);
      expect(profile.lastRoundWasDoubled, isFalse);
      expect(profile.lastRoundCoinsPaid, 10);
      expect(profile.coins, 10, reason: 'no extra credited when already doubled');
    });
  });

  group('weekly goal (P9)', () {
    test('distinct-day count increments once per distinct day', () async {
      // Seed yesterday as last played so today is a new distinct day.
      SharedPreferences.setMockInitialValues({
        'profile_last_day': yesterday,
        'profile_week_key': _weekKeyNow(),
        'profile_week_days_played': 2,
        'profile_daily_streak': 1,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.weekDaysPlayed, 2);

      // First play today: +1.
      await profile.recordPlayDay();
      expect(profile.weekDaysPlayed, 3);

      // Second play the same day: no change (early-return guard).
      await profile.recordPlayDay();
      expect(profile.weekDaysPlayed, 3);
    });

    test('a stale week-key rolls the count over to 0 on load', () async {
      SharedPreferences.setMockInitialValues({
        'profile_week_key': 'W2000-01-03', // long-stale Monday
        'profile_week_days_played': 4,
        'profile_week_claimed': true,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.weekDaysPlayed, 0);
      expect(profile.canClaimWeeklyBonus, isFalse);
    });

    test('canClaimWeeklyBonus triggers at the target and claims once',
        () async {
      // At the target (5) this week, not yet claimed, last played yesterday so
      // today's play does not push it (it would still be claimable anyway).
      SharedPreferences.setMockInitialValues({
        'profile_week_key': _weekKeyNow(),
        'profile_week_days_played': 5,
        'profile_week_claimed': false,
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.weeklyGoalTarget, 5);
      expect(profile.canClaimWeeklyBonus, isTrue);

      final coinsBefore = profile.coins;
      final treatsBefore = profile.petTreats;
      final paid = await profile.claimWeeklyBonus();
      expect(paid, 40);
      expect(profile.coins, coinsBefore + 40);
      expect(profile.petTreats, treatsBefore + 1);
      expect(profile.canClaimWeeklyBonus, isFalse);

      // A second claim pays nothing.
      expect(await profile.claimWeeklyBonus(), 0);
    });
  });
}
