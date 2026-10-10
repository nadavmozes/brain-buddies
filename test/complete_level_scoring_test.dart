// Locks in the shared scoring boundaries used by every GameProgressStore game,
// exercised through WizardState.completeLevel. Stars follow 90/70/50 percent
// thresholds; best stars only ever improve; and a fastest time is recorded only
// on a 3-star run with a real elapsed time, and only when it beats the record.

import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/games/word_wizard/models/wizard_level.dart';
import 'package:brain_buddies/games/word_wizard/services/wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(PlayerProfile, WizardState)> _freshStores() async {
  SharedPreferences.setMockInitialValues({});
  final profile = PlayerProfile();
  await profile.load();
  final state = WizardState();
  await state.load();
  return (profile, state);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // total = 100 so correct == percent exactly (no rounding surprises).
  // 49%->0 stars, 50%->1, 69%->1, 70%->2, 89%->2, 90%->3.
  final boundaries = <(int correct, int stars)>[
    (49, 0),
    (50, 1),
    (69, 1),
    (70, 2),
    (89, 2),
    (90, 3),
  ];

  for (final b in boundaries) {
    test('percent boundary ${b.$1}/100 -> ${b.$2} stars', () async {
      final (profile, state) = await _freshStores();
      final level = WizardMap.allLevels.first;
      final outcome = await state.completeLevel(
        profile: profile,
        level: level,
        correct: b.$1,
        total: 100,
        elapsedSeconds: 0,
      );
      expect(outcome.stars, b.$2);
      expect(state.stars(level.id), b.$2);
    });
  }

  test('best stars never decrease on a worse re-run', () async {
    final (profile, state) = await _freshStores();
    final level = WizardMap.allLevels.first;

    // First run: a strong 90% -> 3 stars.
    await state.completeLevel(
        profile: profile, level: level, correct: 90, total: 100, elapsedSeconds: 0);
    expect(state.stars(level.id), 3);

    // Weaker re-run (50% -> 1 star) must not lower the stored best.
    final worse = await state.completeLevel(
        profile: profile, level: level, correct: 50, total: 100, elapsedSeconds: 0);
    expect(worse.stars, 1, reason: 'this run earned 1 star');
    expect(state.stars(level.id), 3, reason: 'best stays at the earlier best');
  });

  test('fastest time only records on a 3-star run and only when it improves',
      () async {
    final (profile, state) = await _freshStores();
    final level = WizardMap.allLevels.first;

    // Non-3-star run with a real time: no fastest recorded.
    final two = await state.completeLevel(
        profile: profile, level: level, correct: 70, total: 100, elapsedSeconds: 30);
    expect(two.isNewFastest, isFalse);
    expect(state.fastestSeconds(level.id), 0);

    // 3-star run with elapsed 0: still nothing (needs a real time).
    final zeroTime = await state.completeLevel(
        profile: profile, level: level, correct: 90, total: 100, elapsedSeconds: 0);
    expect(zeroTime.isNewFastest, isFalse);
    expect(state.fastestSeconds(level.id), 0);

    // 3-star run with a real time: first record set.
    final first = await state.completeLevel(
        profile: profile, level: level, correct: 90, total: 100, elapsedSeconds: 40);
    expect(first.isNewFastest, isTrue);
    expect(state.fastestSeconds(level.id), 40);

    // Slower 3-star run: does not improve the record.
    final slower = await state.completeLevel(
        profile: profile, level: level, correct: 90, total: 100, elapsedSeconds: 55);
    expect(slower.isNewFastest, isFalse);
    expect(state.fastestSeconds(level.id), 40);

    // Faster 3-star run: new record.
    final faster = await state.completeLevel(
        profile: profile, level: level, correct: 90, total: 100, elapsedSeconds: 25);
    expect(faster.isNewFastest, isTrue);
    expect(state.fastestSeconds(level.id), 25);
  });
}
