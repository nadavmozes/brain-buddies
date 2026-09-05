/// The kinds of Word Wizard questions.
enum WordQuestionType {
  /// Show a picture; pick the word that names it.
  namePicture,

  /// Show a picture + word with a missing letter; pick the missing letter.
  missingLetter,

  /// Show a picture; pick the correctly-spelled word among misspellings.
  correctSpelling,
}

/// A built Word Wizard question.
class WordQuestion {
  WordQuestion({
    required this.type,
    required this.prompt,
    required this.emoji,
    required this.display,
    required this.choices,
    required this.correctIndex,
  });

  final WordQuestionType type;

  /// The instruction line, e.g. "Which word is this?".
  final String prompt;

  /// The picture hint.
  final String emoji;

  /// Extra text under the picture (e.g. "c _ t" for missing-letter), or ''.
  final String display;

  final List<String> choices;
  final int correctIndex;
}
