import 'clock_time.dart';

enum ClockQuestionType {
  /// Show a clock; pick the time label.
  readClock,

  /// Show a time (words); pick the clock that matches.
  findClock,
}

/// A built Clock Hero question. For [readClock] the prompt clock is
/// [promptTime] and choices are text labels. For [findClock] the choices are
/// clock times to render and the prompt is the spoken time.
class ClockQuestion {
  ClockQuestion({
    required this.type,
    required this.prompt,
    required this.correctIndex,
    this.promptTime,
    this.textChoices,
    this.clockChoices,
  });

  final ClockQuestionType type;
  final String prompt;
  final int correctIndex;

  final ClockTime? promptTime;
  final List<String>? textChoices;
  final List<ClockTime>? clockChoices;
}
