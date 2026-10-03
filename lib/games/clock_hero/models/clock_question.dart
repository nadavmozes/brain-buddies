import 'clock_time.dart';

enum ClockQuestionType {
  /// Show a clock; pick the time label.
  readClock,

  /// Show a time (words); pick the clock that matches.
  findClock,

  /// Show a target time; drag the clock hands to match it.
  setClock,

  /// "It's X. What time in N hours?"; pick the resulting time label.
  elapsed,
}

/// A built Clock Hero question.
/// - [readClock]: [promptTime] shown as a clock, [textChoices] are labels.
/// - [findClock]: [clockChoices] are rendered clocks, prompt is the spoken time.
/// - [setClock]: [targetTime] is what the child must set the hands to.
/// - [elapsed]: [promptTime] + prompt text, [textChoices] are time labels.
class ClockQuestion {
  ClockQuestion({
    required this.type,
    required this.prompt,
    required this.correctIndex,
    this.promptTime,
    this.textChoices,
    this.clockChoices,
    this.targetTime,
  });

  final ClockQuestionType type;
  final String prompt;
  final int correctIndex;

  final ClockTime? promptTime;
  final List<String>? textChoices;
  final List<ClockTime>? clockChoices;

  /// For [setClock]: the time the child must dial in.
  final ClockTime? targetTime;
}
