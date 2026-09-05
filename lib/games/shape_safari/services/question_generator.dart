import 'dart:math';

import 'dart:math';

import '../models/habitat.dart';
import '../models/safari_level.dart';
import '../models/shape_kind.dart';
import '../models/shape_question.dart';

/// Generates Shape Safari questions. [difficulty] 0..1 widens the shape pool
/// and mixes in harder question types as it rises. An optional [habitatPool]
/// pins the available shapes to a habitat.
class ShapeQuestionGenerator {
  ShapeQuestionGenerator({Random? random, List<ShapeKind>? habitatPool})
      : _rng = random ?? Random(),
        _habitatPool = habitatPool;

  final Random _rng;
  final List<ShapeKind>? _habitatPool;

  /// Builds a round for a specific trail level, using the habitat's shape pool
  /// and the level's difficulty.
  static List<ShapeQuestion> forLevel(SafariLevel level, {Random? random}) {
    final gen = ShapeQuestionGenerator(
      random: random,
      habitatPool: level.habitat.shapePool,
    );
    return gen.generateRound(
      level.questionCount,
      difficulty: level.difficulty(SafariMap.levelsPerTrail),
    );
  }

  /// The shapes available. When a habitat pool is set it takes priority;
  /// otherwise the pool widens with difficulty.
  List<ShapeKind> _pool(double difficulty) {
    if (_habitatPool != null) return List.of(_habitatPool!);
    if (difficulty < 0.34) return List.of(ShapeKindInfo.basic);
    if (difficulty < 0.67) {
      return [...ShapeKindInfo.basic, ShapeKind.oval, ShapeKind.pentagon];
    }
    return List.of(ShapeKind.values);
  }

  List<ShapeQuestion> generateRound(int count, {double difficulty = 0.4}) {
    return List.generate(count, (i) {
      // Ramp difficulty across the round.
      final d = (difficulty + i / (count * 2)).clamp(0.0, 1.0);
      return generateOne(d);
    });
  }

  ShapeQuestion generateOne(double difficulty) {
    // Pick a question type; harder difficulties unlock more types.
    final types = <ShapeQuestionType>[
      ShapeQuestionType.identify,
      ShapeQuestionType.find,
      if (difficulty >= 0.3) ShapeQuestionType.countSides,
      if (difficulty >= 0.45) ShapeQuestionType.pattern,
    ];
    final type = types[_rng.nextInt(types.length)];
    switch (type) {
      case ShapeQuestionType.identify:
        return _identify(difficulty);
      case ShapeQuestionType.find:
        return _find(difficulty);
      case ShapeQuestionType.countSides:
        return _countSides(difficulty);
      case ShapeQuestionType.pattern:
        return _pattern(difficulty);
    }
  }

  // Show a shape, choose its name.
  ShapeQuestion _identify(double difficulty) {
    final pool = _pool(difficulty);
    final answer = pool[_rng.nextInt(pool.length)];
    final options = _distinctShapes(pool, answer, 4);
    final correctIndex = options.indexOf(answer);
    return ShapeQuestion(
      type: ShapeQuestionType.identify,
      prompt: 'What shape is this?',
      promptShape: answer,
      choices: [for (final s in options) ShapeChoice.text(s.label)],
      correctIndex: correctIndex,
      skillLabel: 'Identify',
    );
  }

  // Give a name, choose the matching shape.
  ShapeQuestion _find(double difficulty) {
    final pool = _pool(difficulty);
    final answer = pool[_rng.nextInt(pool.length)];
    final options = _distinctShapes(pool, answer, 4);
    final correctIndex = options.indexOf(answer);
    return ShapeQuestion(
      type: ShapeQuestionType.find,
      prompt: 'Which one is a ${answer.label}?',
      choices: [for (final s in options) ShapeChoice.shape(s)],
      correctIndex: correctIndex,
      skillLabel: 'Find',
    );
  }

  // Show a straight-sided shape, choose its side count.
  ShapeQuestion _countSides(double difficulty) {
    final straight =
        _pool(difficulty).where((s) => s.hasStraightSides).toList();
    final answer = straight[_rng.nextInt(straight.length)];
    final correctSides = answer.sides;
    final numbers = <int>{correctSides};
    while (numbers.length < 4) {
      final n = 3 + _rng.nextInt(5); // 3..7
      numbers.add(n);
    }
    final list = numbers.toList()..shuffle(_rng);
    return ShapeQuestion(
      type: ShapeQuestionType.countSides,
      prompt: 'How many sides does this shape have?',
      promptShape: answer,
      choices: [for (final n in list) ShapeChoice.text('$n')],
      correctIndex: list.indexOf(correctSides),
      skillLabel: 'Sides',
    );
  }

  // Show an A B A B ... sequence, choose what comes next.
  ShapeQuestion _pattern(double difficulty) {
    final pool = _pool(difficulty);
    final a = pool[_rng.nextInt(pool.length)];
    ShapeKind b;
    do {
      b = pool[_rng.nextInt(pool.length)];
    } while (b == a);

    // Two pattern styles: ABAB or AABB.
    final abab = _rng.nextBool();
    final seq = <ShapeKind>[];
    if (abab) {
      seq.addAll([a, b, a, b]);
    } else {
      seq.addAll([a, a, b, b, a, a]);
    }
    final next = _nextInPattern(seq);

    final options = _distinctShapes(pool, next, 4);
    return ShapeQuestion(
      type: ShapeQuestionType.pattern,
      prompt: 'What comes next?',
      patternSequence: seq,
      choices: [for (final s in options) ShapeChoice.shape(s)],
      correctIndex: options.indexOf(next),
      skillLabel: 'Pattern',
    );
  }

  ShapeKind _nextInPattern(List<ShapeKind> seq) {
    // The visible sequence has a period; continue it.
    // For ABAB (len 4) the next is seq[0]; for AABB-style we detect period 4.
    final period = _detectPeriod(seq);
    return seq[seq.length % period];
  }

  int _detectPeriod(List<ShapeKind> seq) {
    for (var p = 1; p <= seq.length ~/ 2; p++) {
      var ok = true;
      for (var i = 0; i < seq.length; i++) {
        if (seq[i] != seq[i % p]) {
          ok = false;
          break;
        }
      }
      if (ok) return p;
    }
    return seq.length;
  }

  /// Returns [count] distinct shapes that always include [answer], shuffled.
  List<ShapeKind> _distinctShapes(
      List<ShapeKind> pool, ShapeKind answer, int count) {
    final set = <ShapeKind>{answer};
    final candidates = List.of(pool)..shuffle(_rng);
    for (final s in candidates) {
      if (set.length >= count) break;
      set.add(s);
    }
    // If the pool was too small, top up from all shapes.
    if (set.length < count) {
      final extra = List.of(ShapeKind.values)..shuffle(_rng);
      for (final s in extra) {
        if (set.length >= count) break;
        set.add(s);
      }
    }
    return set.toList()..shuffle(_rng);
  }
}
