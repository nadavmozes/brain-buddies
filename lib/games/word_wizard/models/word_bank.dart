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

  // Easy: short CVC / grade-1 sight words with a clear picture.
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
    WordEntry('ant', '🐜'),
    WordEntry('bat', '🦇'),
    WordEntry('cow', '🐮'),
    WordEntry('owl', '🦉'),
    WordEntry('bed', '🛏️'),
    WordEntry('key', '🔑'),
    WordEntry('pen', '🖊️'),
    WordEntry('egg', '🥚'),
    WordEntry('map', '🗺️'),
    WordEntry('box', '📦'),
    WordEntry('ball', '⚽'),
    WordEntry('leaf', '🍃'),
    WordEntry('milk', '🥛'),
    WordEntry('kite', '🪁'),
    WordEntry('bell', '🔔'),
  ];

  // Medium: grade-2 words, mostly 4-5 letters.
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
    WordEntry('shoe', '👟'),
    WordEntry('drum', '🥁'),
    WordEntry('clock', '🕐'),
    WordEntry('chair', '🪑'),
    WordEntry('crab', '🦀'),
    WordEntry('bear', '🐻'),
    WordEntry('lion', '🦁'),
    WordEntry('rain', '🌧️'),
    WordEntry('corn', '🌽'),
    WordEntry('horse', '🐴'),
    WordEntry('mouse', '🐭'),
    WordEntry('candy', '🍬'),
    WordEntry('grape', '🍇'),
    WordEntry('whale', '🐳'),
    WordEntry('pizza', '🍕'),
  ];

  // Hard: grade-3 words, 5+ letters.
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
    WordEntry('rabbit', '🐰'),
    WordEntry('turtle', '🐢'),
    WordEntry('rocket', '🚀'),
    WordEntry('flower', '🌸'),
    WordEntry('monkey', '🐵'),
    WordEntry('banana', '🍌'),
    WordEntry('carrot', '🥕'),
    WordEntry('castle', '🏰'),
    WordEntry('pencil', '✏️'),
    WordEntry('guitar', '🎸'),
    WordEntry('rainbow', '🌈'),
    WordEntry('penguin', '🐧'),
    WordEntry('dolphin', '🐬'),
    WordEntry('balloon', '🎈'),
    WordEntry('dinosaur', '🦖'),
  ];

  static List<WordEntry> forDifficulty(double d) {
    if (d < 0.34) return easy;
    if (d < 0.67) return medium;
    return hard;
  }

  static List<WordEntry> get allWords => [...easy, ...medium, ...hard];
}
