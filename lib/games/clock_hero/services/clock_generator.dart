import 'dart:math';

import '../models/clock_question.dart';
import '../models/clock_time.dart';

/// Generates Clock Hero questions. [difficulty] 0..1 controls which minute
/// values appear (o'clock only → half past → quarters).
class ClockQuestionGenerator {
  ClockQuestionGenerator({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  List<int> _minutesFor(double d) {
    if (d < 0.34) return const [0];
    if (d < 0.67) return const [0, 30];
    return const [0, 30, 15, 45];
  }

  List<ClockQuestion> generateRound(int count, {double difficulty = 0.3}) {
    return List.generate(count, (i) {
      final d = (difficulty + i / (count * 2)).clamp(0.0, 1.0);
      return generateOne(d);
    });
  }

  ClockQuestion generateOne(double difficulty) {
    final readClock = _rng.nextBool();
    return readClock ? _readClock(difficulty) : _findClock(difficulty);
  }

  ClockTime _randomTime(double d) {
    final minutes = _minutesFor(d);
    return ClockTime(_rng.nextInt(12) + 1, minutes[_rng.nextInt(minutes.length)]);
  }

  // Show a clock, pick the time label.
  ClockQuestion _readClock(double d) {
    final answer = _randomTime(d);
    final times = _distinctTimes(d, answer, 4);
    final labels = times.map((t) => t.label).toList();
    return ClockQuestion(
      type: ClockQuestionType.readClock,
      prompt: 'What time is it?',
      promptTime: answer,
      textChoices: labels,
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
