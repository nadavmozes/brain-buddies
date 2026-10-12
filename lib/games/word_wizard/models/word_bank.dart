/// A kid-friendly word paired with a picture (emoji) hint. Used to build
/// spelling and vocabulary questions.
///
/// [word] is the plain spelling (used for letter-choice logic, distractors,
/// and text-to-speech). The optional [promptForm] holds a decorated display
/// spelling (e.g. Hebrew with niqqud) shown on the prompt only, and
/// [translation] holds the English meaning for the bilingual flashcard. Both
/// optionals default to `null`, so every existing English entry is unchanged.
class WordEntry {
  const WordEntry(this.word, this.emoji, {this.translation, this.promptForm});

  final String word;
  final String emoji;

  /// English meaning, shown as a secondary bilingual line (Hebrew bank only).
  final String? translation;

  /// Decorated display spelling for the prompt (e.g. niqqud); falls back to
  /// [word] when absent.
  final String? promptForm;

  /// The spelling to display on the prompt: the decorated [promptForm] when
  /// present, otherwise the plain [word].
  String get displayWord => promptForm ?? word;
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

/// A parallel bank of kid-friendly Hebrew words (grades 1-3), authored and
/// reviewed in .agents/tasks/hebrew-word-list-for-review.md. Each entry's
/// [WordEntry.word] is the PLAIN spelling (used for letter-choice logic and
/// text-to-speech), [WordEntry.promptForm] is the niqqud form shown on the
/// prompt, and [WordEntry.translation] is the English meaning for the
/// bilingual flashcard. Kept separate from [WordBank] so the English set stays
/// byte-identical.
class HebrewWordBank {
  HebrewWordBank._();

  // Easy (short, grade 1) — words #1-22.
  static const List<WordEntry> heEasy = [
    WordEntry('כלב', '🐶', translation: 'dog', promptForm: 'כֶּלֶב'),
    WordEntry('חתול', '🐱', translation: 'cat', promptForm: 'חָתוּל'),
    WordEntry('פרה', '🐮', translation: 'cow', promptForm: 'פָּרָה'),
    WordEntry('דג', '🐟', translation: 'fish', promptForm: 'דָּג'),
    WordEntry('אריה', '🦁', translation: 'lion', promptForm: 'אַרְיֵה'),
    WordEntry('דוב', '🐻', translation: 'bear', promptForm: 'דֹּב'),
    WordEntry('שמש', '☀️', translation: 'sun', promptForm: 'שֶׁמֶשׁ'),
    WordEntry('ירח', '🌙', translation: 'moon', promptForm: 'יָרֵחַ'),
    WordEntry('כוכב', '⭐', translation: 'star', promptForm: 'כּוֹכָב'),
    WordEntry('מים', '💧', translation: 'water', promptForm: 'מַיִם'),
    WordEntry('אש', '🔥', translation: 'fire', promptForm: 'אֵשׁ'),
    WordEntry('עץ', '🌳', translation: 'tree', promptForm: 'עֵץ'),
    WordEntry('פרח', '🌸', translation: 'flower', promptForm: 'פֶּרַח'),
    WordEntry('בית', '🏠', translation: 'house', promptForm: 'בַּיִת'),
    WordEntry('דלת', '🚪', translation: 'door', promptForm: 'דֶּלֶת'),
    WordEntry('כסא', '🪑', translation: 'chair', promptForm: 'כִּסֵּא'),
    WordEntry('ספר', '📖', translation: 'book', promptForm: 'סֵפֶר'),
    WordEntry('כדור', '⚽', translation: 'ball', promptForm: 'כַּדּוּר'),
    WordEntry('יד', '✋', translation: 'hand', promptForm: 'יָד'),
    WordEntry('עין', '👁️', translation: 'eye', promptForm: 'עַיִן'),
    WordEntry('לב', '❤️', translation: 'heart', promptForm: 'לֵב'),
    WordEntry('פה', '👄', translation: 'mouth', promptForm: 'פֶּה'),
  ];

  // Medium (grade 2) — words #23-44.
  static const List<WordEntry> heMedium = [
    WordEntry('סוס', '🐴', translation: 'horse', promptForm: 'סוּס'),
    WordEntry('פיל', '🐘', translation: 'elephant', promptForm: 'פִּיל'),
    WordEntry('קוף', '🐵', translation: 'monkey', promptForm: 'קוֹף'),
    WordEntry('צפור', '🐦', translation: 'bird', promptForm: 'צִפּוֹר'),
    WordEntry('דבורה', '🐝', translation: 'bee', promptForm: 'דְּבוֹרָה'),
    WordEntry('פרפר', '🦋', translation: 'butterfly', promptForm: 'פַּרְפַּר'),
    WordEntry('תפוח', '🍎', translation: 'apple', promptForm: 'תַּפּוּחַ'),
    WordEntry('בננה', '🍌', translation: 'banana', promptForm: 'בָּנָנָה'),
    WordEntry('לחם', '🍞', translation: 'bread', promptForm: 'לֶחֶם'),
    WordEntry('חלב', '🥛', translation: 'milk', promptForm: 'חָלָב'),
    WordEntry('גלידה', '🍦', translation: 'ice cream', promptForm: 'גְּלִידָה'),
    WordEntry('עוגה', '🍰', translation: 'cake', promptForm: 'עוּגָה'),
    WordEntry('שולחן', '🪑', translation: 'table', promptForm: 'שֻׁלְחָן'),
    WordEntry('מטה', '🛏️', translation: 'bed', promptForm: 'מִטָּה'),
    WordEntry('חלון', '🪟', translation: 'window', promptForm: 'חַלּוֹן'),
    WordEntry('מפתח', '🔑', translation: 'key', promptForm: 'מַפְתֵּחַ'),
    WordEntry('שעון', '🕐', translation: 'clock', promptForm: 'שָׁעוֹן'),
    WordEntry('ענן', '☁️', translation: 'cloud', promptForm: 'עָנָן'),
    WordEntry('גשם', '🌧️', translation: 'rain', promptForm: 'גֶּשֶׁם'),
    WordEntry('רגל', '🦶', translation: 'foot', promptForm: 'רֶגֶל'),
    WordEntry('אדום', '🔴', translation: 'red', promptForm: 'אָדֹם'),
    WordEntry('כחול', '🔵', translation: 'blue', promptForm: 'כָּחֹל'),
  ];

  // Hard (grade 3, longer / two-syllable) — words #45-66.
  static const List<WordEntry> heHard = [
    WordEntry("ג'ירפה", '🦒', translation: 'giraffe', promptForm: "גַּ'ירָפָה"),
    WordEntry('תנין', '🐊', translation: 'crocodile', promptForm: 'תַּנִּין'),
    WordEntry('צב', '🐢', translation: 'turtle', promptForm: 'צָב'),
    WordEntry('נחש', '🐍', translation: 'snake', promptForm: 'נָחָשׁ'),
    WordEntry('סנאי', '🐿️', translation: 'squirrel', promptForm: 'סְנָאִי'),
    WordEntry('שוקולד', '🍫', translation: 'chocolate', promptForm: 'שׁוֹקוֹלָד'),
    WordEntry('גבינה', '🧀', translation: 'cheese', promptForm: 'גְּבִינָה'),
    WordEntry('תות', '🍓', translation: 'strawberry', promptForm: 'תּוּת'),
    WordEntry('מכונית', '🚗', translation: 'car', promptForm: 'מְכוֹנִית'),
    WordEntry('אוטובוס', '🚌', translation: 'bus', promptForm: 'אוֹטוֹבּוּס'),
    WordEntry('מטוס', '✈️', translation: 'airplane', promptForm: 'מָטוֹס'),
    WordEntry('אמבטיה', '🛁', translation: 'bathtub', promptForm: 'אַמְבַּטְיָה'),
    WordEntry('מזלג', '🍴', translation: 'fork', promptForm: 'מַזְלֵג'),
    WordEntry('מחברת', '📓', translation: 'notebook', promptForm: 'מַחְבֶּרֶת'),
    WordEntry('עפרון', '✏️', translation: 'pencil', promptForm: 'עִפָּרוֹן'),
    WordEntry('קשת', '🌈', translation: 'rainbow', promptForm: 'קֶשֶׁת'),
    WordEntry('שלג', '❄️', translation: 'snow', promptForm: 'שֶׁלֶג'),
    WordEntry('כוכבים', '🌟', translation: 'stars', promptForm: 'כּוֹכָבִים'),
    WordEntry('אצבע', '👆', translation: 'finger', promptForm: 'אֶצְבַּע'),
    WordEntry('שיניים', '🦷', translation: 'tooth/teeth', promptForm: 'שִׁנַּיִם'),
    WordEntry('ירוק', '🟢', translation: 'green', promptForm: 'יָרֹק'),
    WordEntry('צהוב', '🟡', translation: 'yellow', promptForm: 'צָהֹב'),
  ];

  static List<WordEntry> forDifficulty(double d) {
    if (d < 0.34) return heEasy;
    if (d < 0.67) return heMedium;
    return heHard;
  }

  static List<WordEntry> get allWords => [...heEasy, ...heMedium, ...heHard];
}
