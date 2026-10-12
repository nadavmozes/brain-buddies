import 'dart:math';

import '../../../core/l10n/app_lang.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/localized_catalog.dart';
import '../models/habitat.dart';
import '../models/safari_level.dart';
import '../models/shape_kind.dart';
import '../models/shape_question.dart';

/// Generates Shape Safari questions. [difficulty] 0..1 widens the shape pool
/// and mixes in harder question types as it rises. An optional [habitatPool]
/// pins the available shapes to a habitat.
///
/// [lang] selects the prompt + shape-name language. It is passed in explicitly
/// because the generator is static/stateless (the screen resolves it via
/// `L10n.read` in `initState`, matching the Money Math pattern). English is
/// byte-identical to the original behavior.
class ShapeQuestionGenerator {
  ShapeQuestionGenerator(
      {Random? random, List<ShapeKind>? habitatPool, this.lang = AppLang.en})
      : _rng = random ?? Random(),
        _habitatPool = habitatPool;

  final Random _rng;
  final List<ShapeKind>? _habitatPool;
  final AppLang lang;

  /// Resolved chrome strings for the current language.
  AppStrings get _s => stringsFor(lang == AppLang.he);

  /// The localized name of a shape (Hebrew via `ss.shape.label`, English via
  /// the existing [ShapeKindInfo.label] fallback).
  String _shapeLabel(ShapeKind sh) =>
      LocalizedCatalog.resolve('ss.shape.label', sh.name, sh.label, lang: lang);

  /// Builds a round for a specific trail level, using the habitat's shape pool
  /// and the level's difficulty.
  static List<ShapeQuestion> forLevel(
    SafariLevel level, {
    Random? random,
    AppLang lang = AppLang.en,
  }) {
    final gen = ShapeQuestionGenerator(
      random: random,
      habitatPool: level.habitat.shapePool,
      lang: lang,
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

  /// A signature identifying a question so a round can avoid near-duplicates.
  String _signature(ShapeQuestion q) {
    final seq = q.patternSequence?.map((s) => s.name).join('-') ?? '';
    return '${q.type}|${q.prompt}|${q.promptShape?.name ?? ''}|$seq';
  }

  List<ShapeQuestion> generateRound(int count, {double difficulty = 0.4}) {
    final questions = <ShapeQuestion>[];
    final seen = <String>{};
    for (var i = 0; i < count; i++) {
      // Ramp difficulty across the round.
      final d = (difficulty + i / (count * 2)).clamp(0.0, 1.0);
      ShapeQuestion q;
      var guard = 0;
      do {
        q = generateOne(d);
        guard++;
      } while (seen.contains(_signature(q)) && guard < 25);
      seen.add(_signature(q));
      questions.add(q);
    }
    return questions;
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
      prompt: _s.ssPromptIdentify,
      promptShape: answer,
      choices: [for (final s in options) ShapeChoice.text(_shapeLabel(s))],
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
      prompt: _s.ssPromptFind(_shapeLabel(answer)),
      choices: [for (final s in options) ShapeChoice.shape(s)],
      correctIndex: correctIndex,
      skillLabel: 'Find',
    );
  }

  // Show a straight-sided shape, choose its side count.
  ShapeQuestion _countSides(double difficulty) {
    final straight =
        _pool(difficulty).where((s) => s.hasStraightSides).toList();
    // Guard: every current pool has straight-sided shapes, but if a future
    // pool had none we must not index an empty list — fall back to a simpler
    // question type instead.
    if (straight.isEmpty) return _identify(difficulty);
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
      prompt: _s.ssPromptSides,
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
      prompt: _s.ssPromptPattern,
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
