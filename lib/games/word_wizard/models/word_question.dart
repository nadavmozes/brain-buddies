/// The kinds of Word Wizard questions.
enum WordQuestionType {
  /// Show a picture; pick the word that names it.
  namePicture,

  /// Show a picture + word with a missing letter; pick the missing letter.
  missingLetter,

  /// Show a picture; pick the correctly-spelled word among misspellings.
  correctSpelling,

  /// Show a (Hebrew) word; pick its English translation. Hebrew mode only.
  matchTranslation,
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
    this.word,
    this.translation,
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

  /// The full target word for this question, used for text-to-speech. For
  /// missing-letter questions the full word is not otherwise in the model
  /// (only the masked [display] and single-letter [choices]). Optional for
  /// backward compatibility; falls back to the correct choice.
  final String? word;

  /// The English translation of the prompt word, rendered as a secondary
  /// bilingual line on the flashcard (Hebrew mode only). Null when there is no
  /// translation to show (e.g. all English questions, or matchTranslation
  /// where the translation IS the answer). Optional, defaults to null.
  final String? translation;
}
