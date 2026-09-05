/// A kid-friendly word paired with a picture (emoji) hint. Used to build
/// spelling and vocabulary questions.
class WordEntry {
  const WordEntry(this.word, this.emoji);

  final String word;
  final String emoji;
}

/// A small bank of grade 1-3 words grouped loosely by difficulty.
class WordBank {
  WordBank._();

  // Short, simple words.
  static const List<WordEntry> easy = [
    WordEntry('cat', '🐱'),
    WordEntry('dog', '🐶'),
    WordEntry('sun', '☀️'),
    WordEntry('hat', '🎩'),
    WordEntry('bus', '🚌'),
    WordEntry('cup', '☕'),
    WordEntry('bee', '🐝'),
    WordEntry('pig', '🐷'),
    WordEntry('car', '🚗'),
    WordEntry('fox', '🦊'),
  ];

  // Medium words.
  static const List<WordEntry> medium = [
    WordEntry('frog', '🐸'),
    WordEntry('star', '⭐'),
    WordEntry('fish', '🐟'),
    WordEntry('cake', '🍰'),
    WordEntry('tree', '🌳'),
    WordEntry('book', '📖'),
    WordEntry('moon', '🌙'),
    WordEntry('duck', '🦆'),
    WordEntry('boat', '⛵'),
    WordEntry('bird', '🐦'),
  ];

  // Longer words.
  static const List<WordEntry> hard = [
    WordEntry('apple', '🍎'),
    WordEntry('tiger', '🐯'),
    WordEntry('house', '🏠'),
    WordEntry('robot', '🤖'),
    WordEntry('train', '🚆'),
    WordEntry('snake', '🐍'),
    WordEntry('crown', '👑'),
    WordEntry('cloud', '☁️'),
    WordEntry('sheep', '🐑'),
    WordEntry('bread', '🍞'),
  ];

  static List<WordEntry> forDifficulty(double d) {
    if (d < 0.34) return easy;
    if (d < 0.67) return medium;
    return hard;
  }

  static List<WordEntry> get allWords => [...easy, ...medium, ...hard];
}
