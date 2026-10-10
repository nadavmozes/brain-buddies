// Locks in the hub-wide daily-streak rule in PlayerProfile.recordPlayDay.
//
// recordPlayDay() reads DateTime.now() internally, so seeds are expressed
// RELATIVE to now (yesterday = now - 1 day, etc.). The streak advances only
// when the last played day was the previous calendar day; a same-day call is a
// no-op and any gap resets the streak to 1. The month/year case verifies the
// "yesterday-string" rule still holds when the previous day crosses a boundary.

import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('same-day replay is a no-op (streak unchanged)', () async {
    final today = _dayKey(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'profile_daily_streak': 4,
      'profile_last_day': today,
    });

    final profile = PlayerProfile();
    await profile.load();
    expect(profile.dailyStreak, 4);

    final streak = await profile.recordPlayDay();
    expect(streak, 4, reason: 'playing again the same day must not advance');
    expect(profile.dailyStreak, 4);

    // Persisted value is likewise unchanged.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('profile_daily_streak'), 4);
  });

  test('consecutive day increments the streak by one', () async {
    final yesterday =
        _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    SharedPreferences.setMockInitialValues({
      'profile_daily_streak': 2,
      'profile_last_day': yesterday,
    });

    final profile = PlayerProfile();
    await profile.load();

    final streak = await profile.recordPlayDay();
    expect(streak, 3);
    expect(profile.dailyStreak, 3);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('profile_daily_streak'), 3);
    expect(prefs.getString('profile_last_day'), _dayKey(DateTime.now()));
  });

  test('a missed day resets the streak to 1', () async {
    final threeDaysAgo =
        _dayKey(DateTime.now().subtract(const Duration(days: 3)));
    SharedPreferences.setMockInitialValues({
      'profile_daily_streak': 9,
      'profile_last_day': threeDaysAgo,
    });

    final profile = PlayerProfile();
    await profile.load();

    final streak = await profile.recordPlayDay();
    expect(streak, 1, reason: 'a gap breaks the streak');
    expect(profile.dailyStreak, 1);
  });

  test('fresh profile with no history starts the streak at 1', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();
    expect(profile.dailyStreak, 0);

    final streak = await profile.recordPlayDay();
    expect(streak, 1);
  });

  test('yesterday-string rule holds across a month/year boundary', () async {
    // The previous calendar day of "today" is computed by subtracting one day
    // from now(). Whatever today is, seeding last_day with that exact previous
    // day must count as consecutive — including when now() is the 1st of a
    // month or Jan 1 (where yesterday rolls back the month/year).
    final now = DateTime.now();
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    SharedPreferences.setMockInitialValues({
      'profile_daily_streak': 5,
      'profile_last_day': yesterday,
    });

    final profile = PlayerProfile();
    await profile.load();

    final streak = await profile.recordPlayDay();
    expect(streak, 6,
        reason:
            'the previous calendar day must advance the streak even when it '
            'crosses a month or year boundary');
  });
}
