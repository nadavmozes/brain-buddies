/// A single math question with multiple-choice answers.
class MathProblem {
  MathProblem({
    required this.question,
    required this.answer,
    required this.choices,
    required this.operatorLabel,
  });

  /// The text shown to the player, e.g. "3 + 4".
  final String question;

  /// The correct numeric answer.
  final int answer;

  /// Shuffled answer options (includes the correct answer).
  final List<int> choices;

  /// A short label naming the skill, e.g. "Addition".
  final String operatorLabel;
}
