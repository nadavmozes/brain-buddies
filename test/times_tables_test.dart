// Phase 4 — Times Tables campaign inside Number Quest.
//
// Covers: the multiplication generator (only `× ` facts within 1-12, exact
// count per level, 4 distinct valid choices with the correct product, in-round
// de-dup); the campaign map ids are disjoint from the three worlds and the
// three worlds + dailyLevel are unchanged; campaign unlock gating mirrors the
// other worlds; a perfect run feeds Skill.multiplication / the nq_mult path;
// and the array widget renders at a 430×900 surface without overflow (12×12).

import 'dart:math';

import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/games/number_quest/models/boss.dart';
import 'package:brain_buddies/games/number_quest/models/difficulty.dart';
import 'package:brain_buddies/games/number_quest/models/level.dart';
import 'package:brain_buddies/games/number_quest/models/math_problem.dart';
import 'package:brain_buddies/games/number_quest/models/mult_level.dart';
import 'package:brain_buddies/games/number_quest/models/skill.dart';
import 'package:brain_buddies/games/number_quest/screens/difficulty_screen.dart';
import 'package:brain_buddies/games/number_quest/screens/game_screen.dart';
import 'package:brain_buddies/games/number_quest/screens/result_screen.dart';
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
  // Exactly 4 distinct STRICTLY POSITIVE choices, the correct product present.
  // A 1-12 campaign must never offer 0 as a distractor.
  expect(p.choices.length, 4);
  expect(p.choices.toSet().length, 4, reason: 'choices are distinct');
  expect(p.choices, contains(p.answer));
  for (final c in p.choices) {
    expect(c, greaterThanOrEqualTo(1),
        reason: 'campaign choices are strictly positive (no 0): ${p.choices}');
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

  test('small-answer facts (×1) never offer 0 as a distractor', () {
    // Level 1's window is 1..5, so a×b can be as small as 1 or 2 — the cases
    // where the shared choice builder would otherwise allow a 0 distractor.
    final gen = ProblemGenerator();
    var sawSmall = false;
    for (var i = 0; i < 2000; i++) {
      final p = gen.generateMultRound(
        const MultLevelSpec(minFactor: 1, maxFactor: 2, useArray: true),
        count: 1,
      ).first;
      if (p.answer <= 2) sawSmall = true;
      expect(p.choices, isNot(contains(0)),
          reason: 'no 0 choice for ${p.question} = ${p.answer}');
      for (final c in p.choices) {
        expect(c, greaterThanOrEqualTo(1));
      }
    }
    expect(sawSmall, isTrue, reason: 'the small-answer case was exercised');
  });

  test('completeLevel grants the nq_mult achievement on the 50th mult answer',
      () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();
    final state = GameState();
    await state.load();

    final level = TimesTablesMap.allLevels.first;

    // Answer 49 multiplication questions right — not yet earned.
    for (var i = 0; i < 49; i++) {
      state.recordAnswer(Skill.multiplication, true);
    }
    final before = await state.completeLevel(
      profile: profile,
      level: level,
      correct: 0,
      total: 6,
      roundScore: 0,
      bestAnswerStreak: 0,
      bossDefeated: false,
      elapsedSeconds: 10,
    );
    expect(before.newAchievements.any((a) => a.id == 'nq_mult'), isFalse,
        reason: 'not yet at 50 correct multiplication answers');

    // The 50th correct answer crosses the threshold on the next completion.
    state.recordAnswer(Skill.multiplication, true);
    final after = await state.completeLevel(
      profile: profile,
      level: level,
      correct: 1,
      total: 6,
      roundScore: 10,
      bestAnswerStreak: 1,
      bossDefeated: false,
      elapsedSeconds: 10,
    );
    expect(after.newAchievements.any((a) => a.id == 'nq_mult'), isTrue,
        reason: 'nq_mult earned once 50 multiplication answers are correct');
  });

  test('a boss run reports shared round effects (streak + coins)', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();
    final state = GameState();
    await state.load();

    final boss = TimesTablesMap.allLevels.last;
    expect(boss.isBoss, isTrue);

    final startStreak = profile.dailyStreak;
    final startCoins = profile.coins;

    final outcome = await state.completeLevel(
      profile: profile,
      level: boss,
      correct: 8,
      total: 8,
      roundScore: 80,
      bestAnswerStreak: 8,
      bossDefeated: true,
      elapsedSeconds: 30,
    );

    // onRoundFinished advanced the hub-wide day streak and coins flowed to the
    // shared profile.
    expect(profile.dailyStreak, greaterThanOrEqualTo(startStreak + 1));
    expect(profile.coins, startCoins + outcome.coinsEarned);
    expect(outcome.coinsEarned, greaterThan(0));
    expect(
        outcome.newAchievements.any((a) => a.id == 'nq_boss'), isTrue,
        reason: 'befriending the guardian earns the boss achievement');
  });

  test('next-level routing stays inside the campaign and stops at the boss',
      () {
    final levels = TimesTablesMap.allLevels;
    // From the first level, the "next" is the second campaign level.
    expect(nqNextLevelAfter(levels.first)?.id, levels[1].id);
    // From the boss, there is no next level.
    expect(nqNextLevelAfter(levels.last), isNull);
    // The campaign never leaks into the three worlds' order.
    for (var i = 0; i < levels.length - 1; i++) {
      final next = nqNextLevelAfter(levels[i]);
      expect(next, isNotNull);
      expect(next!.mult, isNotNull,
          reason: 'next level is still a campaign level');
    }
  });

  test('persisted campaign stars reload and reset removes them', () async {
    final level = TimesTablesMap.allLevels.first;
    SharedPreferences.setMockInitialValues({
      'nq_level_${level.id}': 3,
      'nq_fastest_${level.id}': 15,
    });
    final state = GameState();
    await state.load();
    expect(state.stars(level.id), 3, reason: 'stars reload from prefs');
    expect(state.fastestSeconds(level.id), 15);

    await state.reset();
    expect(state.stars(level.id), 0, reason: 'reset clears campaign stars');
    expect(state.fastestSeconds(level.id), 0);
    // And the backing prefs keys are gone.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('nq_level_${level.id}'), isFalse);
    expect(prefs.containsKey('nq_fastest_${level.id}'), isFalse);
  });

  test('the Times Guardian identity is "Times Guardian" / "שומר הכפל"', () {
    // English comes from the boss model (the header fallback source).
    expect(Bosses.timesGuardian.name, 'Times Guardian');
    // Hebrew comes from the catalog entry the header actually resolves.
    final boss = TimesTablesMap.allLevels.last;
    expect(boss.bossId, 'times');
    expect(
      LocalizedCatalog.resolve(
          'nq.boss.name', boss.bossId, boss.boss.name, lang: AppLang.he),
      'שומר הכפל',
    );
    // Under English the fallback (the required identity) is used.
    expect(
      LocalizedCatalog.resolve(
          'nq.boss.name', boss.bossId, boss.boss.name, lang: AppLang.en),
      'Times Guardian',
    );
  });

  testWidgets('Hebrew campaign: recall level localizes the header + skill label',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = PlayerProfile();
    await profile.load();
    final state = GameState();
    await state.load();

    // A non-array recall level (level 4: window 4..10, useArray=false).
    final recall = TimesTablesMap.allLevels[3];
    expect(recall.mult!.useArray, isFalse);

    await tester.pumpWidget(_hebrewHarness(
      GameScreen(level: recall, state: state, profile: profile),
    ));
    await tester.pumpAndSettle();

    // Header shows the Hebrew "שלב 4", not the English "Level 4".
    expect(find.text('שלב 4'), findsOneWidget);
    expect(find.text('Level 4'), findsNothing);
    // Skill label is the Hebrew "כפל" (uppercased is a no-op for Hebrew),
    // never the English "MULTIPLICATION".
    expect(find.text('כפל'), findsOneWidget);
    expect(find.text('MULTIPLICATION'), findsNothing);
  });

  testWidgets('Hebrew array level keeps the equation LTR but the hint RTL',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const hint = 'ספרו את הנקודות!';
    await tester.pumpWidget(_hebrewHarness(
      const Scaffold(
        body: Center(child: MultArrayView(a: 3, b: 4, hint: hint)),
      ),
    ));
    await tester.pumpAndSettle();

    // The equation island reads left-to-right.
    final eqDir = Directionality.of(tester.element(find.text('3 × 4 = ?')));
    expect(eqDir, TextDirection.ltr);
    // The Hebrew hint stays right-to-left (ambient direction, not LTR).
    final hintDir = Directionality.of(tester.element(find.text(hint)));
    expect(hintDir, TextDirection.rtl);
    expect(tester.takeException(), isNull);
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

/// Wraps [child] in a Hebrew [L10n] (RTL) inside a MaterialApp so campaign
/// screens resolve `context.l10n` / `context.tr` to Hebrew and the ambient
/// Directionality is right-to-left.
Widget _hebrewHarness(Widget child) {
  // Force RTL ambient direction (as the real app does under Hebrew) and expose
  // a Hebrew L10n so `context.l10n` / `context.tr` resolve to Hebrew.
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: L10n(
        lang: AppLang.he,
        notifier: ValueNotifier<int>(0),
        child: child,
      ),
    ),
  );
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
