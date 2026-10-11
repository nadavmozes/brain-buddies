// Locks in Number Quest's math correctness: division always resolves to a
// whole-number answer consistent with the printed "dividend ÷ divisor",
// subtraction never goes negative, no choice is ever negative, and the correct
// answer is always among the shuffled choices. Swept across many seeds over the
// whole map plus forced expert rounds (the only tier that emits division).

import 'dart:math';

import 'package:brain_buddies/games/number_quest/models/difficulty.dart';
import 'package:brain_buddies/games/number_quest/models/level.dart';
import 'package:brain_buddies/games/number_quest/models/math_problem.dart';
import 'package:brain_buddies/games/number_quest/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates one problem's math against its printed question + label.
void _check(MathProblem p) {
  // Correct answer is present among the choices, none of which are negative.
  expect(p.choices, contains(p.answer));
  for (final c in p.choices) {
    expect(c, greaterThanOrEqualTo(0), reason: 'no negative choices: $c');
  }

  switch (p.operatorLabel) {
    case 'Division':
      final parts = p.question.split('÷');
      expect(parts.length, 2, reason: 'division format: ${p.question}');
      final dividend = int.parse(parts[0].trim());
      final divisor = int.parse(parts[1].trim());
      expect(divisor, greaterThan(0));
      expect(dividend % divisor, 0,
          reason: 'division must be whole: ${p.question}');
      expect(p.answer, dividend ~/ divisor,
          reason: 'answer matches the quotient: ${p.question}');
      break;
    case 'Subtraction':
      final parts = p.question.split('-');
      expect(parts.length, 2);
      final a = int.parse(parts[0].trim());
      final b = int.parse(parts[1].trim());
      expect(p.answer, a - b);
      expect(p.answer, greaterThanOrEqualTo(0),
          reason: 'subtraction never negative: ${p.question}');
      break;
    case 'Addition':
      final parts = p.question.split('+');
      expect(parts.length, 2);
      final a = int.parse(parts[0].trim());
      final b = int.parse(parts[1].trim());
      expect(p.answer, a + b);
      break;
    case 'Multiplication':
      final parts = p.question.split('×');
      expect(parts.length, 2);
      final a = int.parse(parts[0].trim());
      final b = int.parse(parts[1].trim());
      expect(p.answer, a * b);
      break;
    default:
      fail('unexpected operator label: ${p.operatorLabel}');
  }
}

void main() {
  test('every map level produces mathematically valid problems', () {
    for (var seed = 0; seed <= 60; seed++) {
      for (final level in WorldMap.allLevels) {
        final qs = ProblemGenerator.forLevel(level, random: Random(seed));
        for (final p in qs) {
          _check(p);
        }
      }
    }
  });

  test('forced expert rounds produce valid division (and friends)', () {
    var sawDivision = false;
    for (var seed = 0; seed <= 60; seed++) {
      final gen = ProblemGenerator(random: Random(seed));
      final qs = gen.generateRound(Difficulty.expert, count: 20);
      for (final p in qs) {
        _check(p);
        if (p.operatorLabel == 'Division') sawDivision = true;
      }
    }
    expect(sawDivision, isTrue,
        reason: 'expert rounds should surface division questions');
  });
}
