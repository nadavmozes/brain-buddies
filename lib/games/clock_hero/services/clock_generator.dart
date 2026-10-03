import 'dart:math';

import '../models/clock_question.dart';
import '../models/clock_time.dart';
import '../models/time_world.dart';

/// Generates Clock Hero questions. [difficulty] 0..1 controls minute precision
/// and which question types appear. A [minutePool] (from a world) pins the
/// allowed minutes.
class ClockQuestionGenerator {
  ClockQuestionGenerator({Random? random, List<int>? minutePool})
      : _rng = random ?? Random(),
        _worldMinutes = minutePool;

  final Random _rng;
  final List<int>? _worldMinutes;

  /// Builds a round for a specific trail level using the world's minute pool
  /// and the level's difficulty.
  static List<ClockQuestion> forLevel(ClockLevel level, {Random? random}) {
    final gen = ClockQuestionGenerator(
      random: random,
      minutePool: level.world.minutePool,
    );
    return gen.generateRound(
      level.questionCount,
      difficulty: level.difficulty(ClockMap.levelsPerTrail),
    );
  }

  List<int> _minutesFor(double d) {
    if (_worldMinutes != null) return _worldMinutes!;
    if (d < 0.34) return const [0];
    if (d < 0.67) return const [0, 30];
    return const [0, 30, 15, 45];
  }

  String _signature(ClockQuestion q) =>
      '${q.type}|${q.prompt}|${q.promptTime?.label ?? ''}|${q.targetTime?.label ?? ''}';

  List<ClockQuestion> generateRound(int count, {double difficulty = 0.3}) {
    final questions = <ClockQuestion>[];
    final seen = <String>{};
    for (var i = 0; i < count; i++) {
      final d = (difficulty + i / (count * 2)).clamp(0.0, 1.0);
      ClockQuestion q;
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

  ClockQuestion generateOne(double difficulty) {
    // Harder difficulty unlocks the richer question types.
    final types = <ClockQuestionType>[
      ClockQuestionType.readClock,
      ClockQuestionType.findClock,
      if (difficulty >= 0.3) ClockQuestionType.setClock,
      if (difficulty >= 0.55) ClockQuestionType.elapsed,
    ];
    final type = types[_rng.nextInt(types.length)];
    switch (type) {
      case ClockQuestionType.readClock:
        return _readClock(difficulty);
      case ClockQuestionType.findClock:
        return _findClock(difficulty);
      case ClockQuestionType.setClock:
        return _setClock(difficulty);
      case ClockQuestionType.elapsed:
        return _elapsed(difficulty);
    }
  }

  ClockTime _randomTime(double d) {
    final minutes = _minutesFor(d);
    return ClockTime(
        _rng.nextInt(12) + 1, minutes[_rng.nextInt(minutes.length)]);
  }

  // Show a clock, pick the time label.
  ClockQuestion _readClock(double d) {
    final answer = _randomTime(d);
    final times = _distinctTimes(d, answer, 4);
    return ClockQuestion(
      type: ClockQuestionType.readClock,
      prompt: 'What time is it?',
      promptTime: answer,
      textChoices: times.map((t) => t.label).toList(),
      correctIndex: times.indexOf(answer),
    );
  }

  // Show the spoken time, pick the matching clock.
  ClockQuestion _findClock(double d) {
    final answer = _randomTime(d);
    final times = _distinctTimes(d, answer, 4);
    return ClockQuestion(
      type: ClockQuestionType.findClock,
      prompt: 'Which clock shows ${answer.spoken}?',
      clockChoices: times,
      correctIndex: times.indexOf(answer),
    );
  }

  // Drag the hands to match a target time.
  ClockQuestion _setClock(double d) {
    final target = _randomTime(d);
    return ClockQuestion(
      type: ClockQuestionType.setClock,
      prompt: 'Set the clock to ${target.spoken}',
      targetTime: target,
      correctIndex: 0, // not used; correctness checked against targetTime
    );
  }

  // Elapsed time: "It's X. What time in N hours?"
  ClockQuestion _elapsed(double d) {
    final start = _randomTime(d);
    final hours = _rng.nextInt(3) + 1; // 1..3 hours
    final answer = start.addHours(hours);
    final times = _distinctTimes(d, answer, 4);
    final hourWord = hours == 1 ? '1 hour' : '$hours hours';
    return ClockQuestion(
      type: ClockQuestionType.elapsed,
      prompt: "It's ${start.spoken}. What time in $hourWord?",
      promptTime: start,
      textChoices: times.map((t) => t.label).toList(),
      correctIndex: times.indexOf(answer),
    );
  }

  List<ClockTime> _distinctTimes(double d, ClockTime answer, int count) {
    final set = <ClockTime>{answer};
    var guard = 0;
    while (set.length < count && guard < 60) {
      guard++;
      set.add(_randomTime(d));
    }
    // Ensure enough distinct options even at the easiest setting (o'clock).
    var h = 1;
    while (set.length < count) {
      set.add(ClockTime(h, answer.minute));
      h++;
    }
    return set.toList()..shuffle(_rng);
  }
}
