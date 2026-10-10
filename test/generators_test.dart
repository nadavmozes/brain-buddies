// Locks in the structural contract of all five question generators: each round
// has exactly level.questionCount questions, every multiple-choice question
// exposes the expected number of DISTINCT options with correctIndex in range
// (and pointing at the correct value where the model exposes it), and the
// de-dup guard keeps questions mostly unique within a round.
//
// All sweeps use seeded Random so results are deterministic across runs.

import 'dart:math';

import 'package:brain_buddies/games/clock_hero/models/clock_question.dart';
import 'package:brain_buddies/games/clock_hero/models/time_world.dart';
import 'package:brain_buddies/games/clock_hero/services/clock_generator.dart';
import 'package:brain_buddies/games/money_math/models/money_level.dart';
import 'package:brain_buddies/games/money_math/models/money_question.dart';
import 'package:brain_buddies/games/money_math/services/money_generator.dart';
import 'package:brain_buddies/games/number_quest/models/level.dart';
import 'package:brain_buddies/games/number_quest/services/problem_generator.dart';
import 'package:brain_buddies/games/shape_safari/models/safari_level.dart';
import 'package:brain_buddies/games/shape_safari/models/shape_question.dart';
import 'package:brain_buddies/games/shape_safari/services/question_generator.dart';
import 'package:brain_buddies/games/word_wizard/models/wizard_level.dart';
import 'package:brain_buddies/games/word_wizard/services/word_generator.dart';
import 'package:flutter_test/flutter_test.dart';

const _seeds = [0, 1, 2, 3, 7, 13, 42];

/// Asserts a round is mostly unique: distinct signatures >= count-1, or >= 70%
/// of the count. Kept loose so the ~25-try de-dup guard never makes it flaky.
void _expectMostlyUnique(int distinct, int count, String where) {
  final floor =
      (count - 1) < (count * 0.7).floor() ? (count - 1) : (count * 0.7).floor();
  expect(distinct, greaterThanOrEqualTo(floor),
      reason: '$where: expected mostly-unique questions in a round');
}

void main() {
  test('Number Quest: structure + distinct int choices', () {
    for (final level in WorldMap.allLevels) {
      for (final seed in _seeds) {
        final qs = ProblemGenerator.forLevel(level, random: Random(seed));
        expect(qs.length, level.questionCount);
        final sigs = <String>{};
        for (final q in qs) {
          expect(q.choices.length, 4);
          expect(q.choices.toSet().length, 4,
              reason: 'NQ choices must be distinct');
          expect(q.choices, contains(q.answer));
          sigs.add(q.question);
        }
        _expectMostlyUnique(sigs.length, qs.length, 'NQ ${level.id} seed $seed');
      }
    }
  });

  test('Shape Safari: structure + 4 distinct shape choices', () {
    for (final level in SafariMap.allLevels) {
      for (final seed in _seeds) {
        final qs = ShapeQuestionGenerator.forLevel(level, random: Random(seed));
        expect(qs.length, level.questionCount);
        final sigs = <String>{};
        for (final q in qs) {
          expect(q.choices.length, 4);
          // Distinct by the rendered identity (shape name or text).
          final keys = q.choices
              .map((c) => c.isShape ? 'shape:${c.shape!.name}' : 'text:${c.text}')
              .toSet();
          expect(keys.length, 4, reason: 'Shape choices must be distinct');
          expect(q.correctIndex, inInclusiveRange(0, q.choices.length - 1));
          final seq = q.patternSequence?.map((s) => s.name).join('-') ?? '';
          sigs.add('${q.type}|${q.prompt}|${q.promptShape?.name ?? ''}|$seq');
        }
        _expectMostlyUnique(
            sigs.length, qs.length, 'Safari ${level.id} seed $seed');
      }
    }
  });

  test('Word Wizard: structure + 4 distinct string choices', () {
    for (final level in WizardMap.allLevels) {
      for (final seed in _seeds) {
        final qs = WordQuestionGenerator.forLevel(level, random: Random(seed));
        expect(qs.length, level.questionCount);
        final sigs = <String>{};
        for (final q in qs) {
          expect(q.choices.length, 4);
          expect(q.choices.toSet().length, 4,
              reason: 'Word choices must be distinct');
          expect(q.correctIndex, inInclusiveRange(0, q.choices.length - 1));
          sigs.add('${q.type}|${q.emoji}|${q.display}|${q.choices[q.correctIndex]}');
        }
        _expectMostlyUnique(
            sigs.length, qs.length, 'Wizard ${level.id} seed $seed');
      }
    }
  });

  test('Clock Hero: structure + 4 distinct choices (setClock skipped)', () {
    for (final level in ClockMap.allLevels) {
      for (final seed in _seeds) {
        final qs = ClockQuestionGenerator.forLevel(level, random: Random(seed));
        expect(qs.length, level.questionCount);
        final sigs = <String>{};
        for (final q in qs) {
          switch (q.type) {
            case ClockQuestionType.readClock:
            case ClockQuestionType.elapsed:
              final c = q.textChoices!;
              expect(c.length, 4);
              expect(c.toSet().length, 4, reason: 'clock text choices distinct');
              expect(q.correctIndex, inInclusiveRange(0, c.length - 1));
              break;
            case ClockQuestionType.findClock:
              final c = q.clockChoices!;
              expect(c.length, 4);
              expect(c.map((t) => t.label).toSet().length, 4,
                  reason: 'clock face choices distinct');
              expect(q.correctIndex, inInclusiveRange(0, c.length - 1));
              break;
            case ClockQuestionType.setClock:
              // No choice list to assert on; just a valid target.
              expect(q.targetTime, isNotNull);
              break;
          }
          sigs.add(
              '${q.type}|${q.prompt}|${q.promptTime?.label ?? ''}|${q.targetTime?.label ?? ''}');
        }
        _expectMostlyUnique(
            sigs.length, qs.length, 'Clock ${level.id} seed $seed');
      }
    }
  });

  test('Money Math: structure + type-aware distinct choices', () {
    for (final level in MoneyMap.allLevels) {
      for (final seed in _seeds) {
        final qs = MoneyQuestionGenerator.forLevel(level, random: Random(seed));
        expect(qs.length, level.questionCount);
        final sigs = <String>{};
        for (final q in qs) {
          switch (q.type) {
            case MoneyQuestionType.countCoins:
            case MoneyQuestionType.makeChange:
              final c = q.textChoices!;
              expect(c.length, 4);
              expect(c.toSet().length, 4, reason: 'money text choices distinct');
              expect(q.correctIndex, inInclusiveRange(0, c.length - 1));
              break;
            case MoneyQuestionType.makeAmount:
              final c = q.pileChoices!;
              expect(c.length, 4);
              // Piles are distinct by total value.
              expect(c.map((p) => p.total).toSet().length, 4,
                  reason: 'makeAmount pile totals distinct');
              expect(q.correctIndex, inInclusiveRange(0, c.length - 1));
              break;
            case MoneyQuestionType.whichMore:
              expect(q.pileA, isNotNull);
              expect(q.pileB, isNotNull);
              expect(q.pileA!.total, isNot(q.pileB!.total),
                  reason: 'whichMore piles must differ in total');
              expect(q.correctIndex, inInclusiveRange(0, 1));
              // correctIndex points at the richer pile.
              final richerIsA = q.pileA!.total > q.pileB!.total;
              expect(q.correctIndex, richerIsA ? 0 : 1);
              break;
          }
          final a = q.pile?.total ?? q.pileA?.total ?? 0;
          final b = q.pileB?.total ?? 0;
          sigs.add('${q.type}|${q.prompt}|$a|$b');
        }
        _expectMostlyUnique(
            sigs.length, qs.length, 'Money ${level.id} seed $seed');
      }
    }
  });
}
