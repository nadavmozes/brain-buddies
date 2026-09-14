import 'dart:math';

import '../models/difficulty.dart';
import '../models/level.dart';
import '../models/math_problem.dart';

/// Generates age-appropriate math problems for each difficulty tier.
///
/// Supports adaptive difficulty: a [challenge] multiplier scales the number
/// ranges up or down so the game stays in the child's "sweet spot".
class ProblemGenerator {
  ProblemGenerator({Random? random, double challenge = 1.0})
      : _rng = random ?? Random(),
        _challenge = challenge.clamp(0.5, 1.6);

  final Random _rng;
  final double _challenge;

  /// Scales a base range size by the challenge multiplier (min 1).
  int _scale(int base) => max(1, (base * _challenge).round());

  /// Returns a list of [count] problems for the given [difficulty], avoiding
  /// repeated questions where the pool allows it.
  List<MathProblem> generateRound(Difficulty difficulty, {int? count}) {
    final total = count ?? difficulty.questionsPerRound;
    final problems = <MathProblem>[];
    final seen = <String>{};
    for (var i = 0; i < total; i++) {
      MathProblem p;
      var guard = 0;
      do {
        p = generateOne(difficulty);
        guard++;
      } while (seen.contains(p.question) && guard < 25);
      seen.add(p.question);
      problems.add(p);
    }
    return problems;
  }

  /// Builds a round for a specific map level. Later levels in a world are a
  /// touch harder, and [recentAccuracy] (0..1) nudges the challenge so kids
  /// who are breezing through get tougher questions and vice versa.
  static List<MathProblem> forLevel(
    GameLevel level, {
    double recentAccuracy = 0.7,
    Random? random,
  }) {
    // Base ramps from ~0.8 at level 1 to ~1.2 at the boss.
    final ramp = 0.8 + (level.index / (WorldMap.levelsPerWorld - 1)) * 0.4;
    // Adaptive nudge: high accuracy -> harder, low -> easier.
    final adaptive = ((recentAccuracy - 0.7) * 0.6);
    final challenge = ramp + adaptive;
    final gen = ProblemGenerator(random: random, challenge: challenge);
    return gen.generateRound(level.world, count: level.questionCount);
  }

  /// Generates a single problem tuned to the difficulty tier.
  MathProblem generateOne(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return _easyProblem();
      case Difficulty.intermediate:
        return _intermediateProblem();
      case Difficulty.expert:
        return _expertProblem();
    }
  }

  // Grade 1: addition and subtraction within 20, no negative answers.
  MathProblem _easyProblem() {
    final isAddition = _rng.nextBool();
    if (isAddition) {
      final a = _rng.nextInt(_scale(10)) + 1;
      final b = _rng.nextInt(_scale(10)) + 1;
      return _build('$a + $b', a + b, 'Addition');
    } else {
      final a = _rng.nextInt(_scale(15)) + 5;
      final b = _rng.nextInt(a) + 1; // 1..a  (keeps result >= 0)
      return _build('$a - $b', a - b, 'Subtraction');
    }
  }

  // Grade 2: larger add/subtract within 100 plus small multiplication.
  MathProblem _intermediateProblem() {
    final pick = _rng.nextInt(3);
    if (pick == 0) {
      final a = _rng.nextInt(_scale(50)) + 10;
      final b = _rng.nextInt(_scale(40)) + 1;
      return _build('$a + $b', a + b, 'Addition');
    } else if (pick == 1) {
      final a = _rng.nextInt(_scale(60)) + 20;
      final b = _rng.nextInt(a - 1) + 1;
      return _build('$a - $b', a - b, 'Subtraction');
    } else {
      final a = _rng.nextInt(_scale(5)) + 1;
      final b = _rng.nextInt(_scale(5)) + 1;
      return _build('$a × $b', a * b, 'Multiplication');
    }
  }

  // Grade 3: multiplication, division, and mixed challenges.
  MathProblem _expertProblem() {
    final pick = _rng.nextInt(4);
    if (pick == 0) {
      final a = _rng.nextInt(_scale(9)) + 2;
      final b = _rng.nextInt(_scale(9)) + 2;
      return _build('$a × $b', a * b, 'Multiplication');
    } else if (pick == 1) {
      // Build a clean division with a whole-number answer.
      final divisor = _rng.nextInt(_scale(9)) + 2;
      final quotient = _rng.nextInt(_scale(9)) + 2;
      final dividend = divisor * quotient;
      return _build('$dividend ÷ $divisor', quotient, 'Division');
    } else if (pick == 2) {
      final a = _rng.nextInt(_scale(400)) + 100;
      final b = _rng.nextInt(_scale(300)) + 50;
      return _build('$a + $b', a + b, 'Addition');
    } else {
      final a = _rng.nextInt(_scale(400)) + 100;
      final b = _rng.nextInt(a - 1) + 1;
      return _build('$a - $b', a - b, 'Subtraction');
    }
  }

  /// Wraps a question with a set of plausible multiple-choice options.
  MathProblem _build(String question, int answer, String label) {
    final choices = _buildChoices(answer);
    return MathProblem(
      question: question,
      answer: answer,
      choices: choices,
      operatorLabel: label,
    );
  }

  /// Produces 4 unique options including the correct answer, with
  /// distractors that stay close to the answer so guesses feel real.
  List<int> _buildChoices(int answer) {
    final options = <int>{answer};
    var guard = 0;
    while (options.length < 4 && guard < 50) {
      guard++;
      final spread = max(2, (answer * 0.3).round());
      var delta = _rng.nextInt(spread * 2 + 1) - spread; // -spread..spread
      if (delta == 0) delta = _rng.nextBool() ? 1 : -1;
      final candidate = answer + delta;
      if (candidate >= 0) {
        options.add(candidate);
      }
    }
    // Fallback in case the loop could not find enough distinct values.
    var filler = answer + 1;
    while (options.length < 4) {
      if (filler >= 0) options.add(filler);
      filler++;
    }
    final list = options.toList()..shuffle(_rng);
    return list;
  }
}
