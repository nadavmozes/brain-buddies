// Phase 4 — Times Tables campaign inside Number Quest.
//
// Covers: the multiplication generator (only `× ` facts within 1-12, exact
// count per level, 4 distinct valid choices with the correct product, in-round
// de-dup); the campaign map ids are disjoint from the three worlds and the
// three worlds + dailyLevel are unchanged; campaign unlock gating mirrors the
// other worlds; a perfect run feeds Skill.multiplication / the nq_mult path;
// and the array widget renders at a 430×900 surface without overflow (12×12).

import 'dart:math';

import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/games/number_quest/models/difficulty.dart';
import 'package:brain_buddies/games/number_quest/models/level.dart';
import 'package:brain_buddies/games/number_quest/models/math_problem.dart';
import 'package:brain_buddies/games/number_quest/models/skill.dart';
import 'package:brain_buddies/games/number_quest/screens/difficulty_screen.dart';
import 'package:brain_buddies/games/number_quest/services/game_state.dart';
import 'package:brain_buddies/games/number_quest/services/problem_generator.dart';
import 'package:brain_buddies/games/number_quest/widgets/mult_array_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Validates a single multiplication problem.
void _checkMult(MathProblem p) {
  expect(p.operatorLabel, 'Multiplication',
      reason: 'Times Tables emits only multiplication');
  final parts = p.question.split('×');
  expect(parts.length, 2, reason: 'format "a × b": ${p.question}');
  final a = int.parse(parts[0].trim());
  final b = int.parse(parts[1].trim());
  // Factors inside the overall 1-12 range.
  expect(a, inInclusiveRange(1, 12));
  expect(b, inInclusiveRange(1, 12));
  // Product correctness and no odd zero/negative products.
  expect(p.answer, a * b);
  expect(p.answer, greaterThanOrEqualTo(1));
  // Exactly 4 distinct non-negative choices, the correct product present.
  expect(p.choices.length, 4);
  expect(p.choices.toSet().length, 4, reason: 'choices are distinct');
  expect(p.choices, contains(p.answer));
  for (final c in p.choices) {
    expect(c, greaterThanOrEqualTo(0));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every Times Tables level emits valid multiplication-only facts', () {
    for (var seed = 0; seed <= 80; seed++) {
      for (final level in TimesTablesMap.allLevels) {
        final qs = ProblemGenerator.forLevel(level, random: Random(seed));
        expect(qs.length, level.questionCount,
            reason: 'exactly questionCount per level');
        for (final p in qs) {
          _checkMult(p);
        }
      }
    }
  });

  test('a teaching level stays inside its narrow factor window', () {
    final level = TimesTablesMap.allLevels.first; // 1..5 window
    for (var seed = 0; seed <= 40; seed++) {
      final qs = ProblemGenerator.forLevel(level, random: Random(seed));
      for (final p in qs) {
        final parts = p.question.split('×');
        final a = int.parse(parts[0].trim());
        final b = int.parse(parts[1].trim());
        expect(a, inInclusiveRange(1, 5));
        expect(b, inInclusiveRange(1, 5));
      }
    }
  });

  test('round de-dups within the pool where possible', () {
    // Pick a level whose factor window is large enough that 8 distinct facts
    // exist; the boss (1..12) easily satisfies this.
    final boss = TimesTablesMap.allLevels.last;
    for (var seed = 0; seed <= 40; seed++) {
      final qs = ProblemGenerator.forLevel(boss, random: Random(seed));
      final questions = qs.map((p) => p.question).toList();
      expect(questions.toSet().length, questions.length,
          reason: 'no duplicate questions when the pool is ample');
    }
  });

  test('campaign ids are disjoint from the three worlds', () {
    final worldIds = WorldMap.allLevels.map((l) => l.id).toSet();
    final campaignIds = TimesTablesMap.allLevels.map((l) => l.id).toSet();
    expect(worldIds.intersection(campaignIds), isEmpty);
    expect(campaignIds.length, TimesTablesMap.levelCount);
    // Every campaign id uses the dedicated prefix.
    for (final id in campaignIds) {
      expect(id.startsWith('${TimesTablesMap.idPrefix}_'), isTrue);
    }
  });

  test('the three worlds and dailyLevel are unchanged', () {
    // 3 worlds × 6 levels each.
    expect(WorldMap.allLevels.length, 18);
    expect(WorldMap.levelsPerWorld, 6);
    // dailyLevel rotates its world mod 3 (never mod 4).
    final day3 = WorldMap.dailyLevel(DateTime(2024, 1, 3)); // 3 % 3 == 0
    final day4 = WorldMap.dailyLevel(DateTime(2024, 1, 4)); // 4 % 3 == 1
    expect(day3.world, Difficulty.values[0]);
    expect(day4.world, Difficulty.values[1]);
    expect(day3.mult, isNull, reason: 'daily is not a Times Tables level');
  });

  test('campaign unlock: first open, later gated by prior campaign star',
      () async {
    final levels = TimesTablesMap.allLevels;
    final first = levels.first;
    final second = levels[1];
    final third = levels[2];

    SharedPreferences.setMockInitialValues({});
    final fresh = GameState();
    await fresh.load();
    expect(fresh.isLevelUnlocked(first), isTrue);
    expect(fresh.isLevelUnlocked(second), isFalse);
    expect(fresh.isLevelUnlocked(third), isFalse);

    SharedPreferences.setMockInitialValues({'nq_level_${first.id}': 1});
    final seeded = GameState();
    await seeded.load();
    expect(seeded.isLevelUnlocked(first), isTrue);
    expect(seeded.isLevelUnlocked(second), isTrue);
    expect(seeded.isLevelUnlocked(third), isFalse);
  });

  test('a perfect campaign run feeds multiplication tracking + stars',
      () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();
    final state = GameState();
    await state.load();

    final level = TimesTablesMap.allLevels.first;
    // Simulate answering every question correctly for skill tracking.
    const correct = 6;
    for (var i = 0; i < correct; i++) {
      state.recordAnswer(Skill.multiplication, true);
    }
    final outcome = await state.completeLevel(
      profile: profile,
      level: level,
      correct: correct,
      total: correct,
      roundScore: 60,
      bestAnswerStreak: correct,
      bossDefeated: false,
      elapsedSeconds: 20,
    );

    expect(outcome.stars, 3, reason: 'a perfect run earns 3 stars');
    expect(state.stars(level.id), 3);
    expect(outcome.isNewFastest, isTrue,
        reason: 'a 3-star run with a real time records a fastest');
    expect(state.fastestSeconds(level.id), 20);
    expect(state.skillStat(Skill.multiplication).attempts, correct);
    expect(state.skillStat(Skill.multiplication).correct, correct);
    expect(outcome.coinsEarned, greaterThan(0));
  });

  testWidgets('Times Tables tile shows in the NQ world select and opens trail',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _NqWorldSelectHarness());
    await tester.pumpAndSettle();

    // The campaign tile appears alongside the three difficulty worlds.
    expect(find.text('Times Tables World'), findsOneWidget);

    // Tapping it opens the campaign trail (its own guardian-ending map).
    await tester.tap(find.text('Times Tables World'));
    await tester.pumpAndSettle();
    expect(find.text('✖️ Times Tables World'), findsOneWidget);
    // First campaign stop is unlocked (shows a numbered node), later locked.
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets('the 12×12 array renders without overflow at 430×900',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: MultArrayView(a: 12, b: 12, hint: 'Count the dots!'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12 × 12 = ?'), findsOneWidget);
    // No render overflow was thrown.
    expect(tester.takeException(), isNull);
  });
}

/// Loads a fresh profile + game state, then shows the Number Quest world
/// select. Defaults to English via the L10n fallback (no L10n ancestor).
class _NqWorldSelectHarness extends StatefulWidget {
  const _NqWorldSelectHarness();

  @override
  State<_NqWorldSelectHarness> createState() => _NqWorldSelectHarnessState();
}

class _NqWorldSelectHarnessState extends State<_NqWorldSelectHarness> {
  PlayerProfile? _profile;
  GameState? _state;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final profile = PlayerProfile();
    await profile.load();
    final state = GameState();
    await state.load();
    if (mounted) setState(() {
      _profile = profile;
      _state = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final state = _state;
    return MaterialApp(
      home: profile == null || state == null
          ? const SizedBox()
          : DifficultyScreen(state: state, profile: profile),
    );
  }
}
