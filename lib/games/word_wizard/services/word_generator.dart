import 'dart:math';

import '../../../core/l10n/app_lang.dart';
import '../models/word_bank.dart';
import '../models/word_question.dart';
import '../models/wizard_level.dart';

/// The Hebrew letters offered as missing-letter choices. Niqqud is OFF and
/// final/sofit forms (ך ם ן ף ץ) are excluded to keep the choice buttons clean
/// and unambiguous for young readers.
const String heAlphabet = 'אבגדהוזחטיכלמנסעפצקרשת';

/// Generates Word Wizard questions. [difficulty] 0..1 selects the word pool
/// and mixes in harder question types. [lang] selects the English or Hebrew
/// word bank + question types; it is passed in explicitly because generators
/// are static/stateless (the screen resolves it via L10n.read in initState).
class WordQuestionGenerator {
  WordQuestionGenerator({Random? random, this.lang = AppLang.en})
      : _rng = random ?? Random();

  final Random _rng;
  final AppLang lang;

  /// Builds a round for a specific spellbook level using its difficulty.
  static List<WordQuestion> forLevel(
    WizardLevel level, {
    Random? random,
    AppLang lang = AppLang.en,
  }) {
    final gen = WordQuestionGenerator(random: random, lang: lang);
    return gen.generateRound(
      level.questionCount,
      difficulty: level.difficulty(WizardMap.levelsPerChapter),
    );
  }

  /// A signature so a round can avoid repeating the same question.
  String _signature(WordQuestion q) =>
      '${q.type}|${q.emoji}|${q.display}|${q.choices[q.correctIndex]}';

  List<WordQuestion> generateRound(int count, {double difficulty = 0.3}) {
    final questions = <WordQuestion>[];
    final seen = <String>{};
    for (var i = 0; i < count; i++) {
      final d = (difficulty + i / (count * 2)).clamp(0.0, 1.0);
      WordQuestion q;
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

  // Future work: a 4th "rhyme" or "first-sound" question type would be a nice
  // addition (e.g. "Which word rhymes with cat?" or "Which word starts with the
  // same sound as sun?"). It is intentionally NOT added here because it does not
  // fit the current WordQuestion model / generator with zero churn: rhyme needs
  // a rhyme-group field on WordEntry (or a phonetic grouping), and first-sound
  // needs distractors chosen by initial letter. Both would require new model
  // fields and a new type branch, so they are deferred.
  WordQuestion generateOne(double difficulty) {
    if (lang == AppLang.he) {
      final types = <WordQuestionType>[
        WordQuestionType.namePicture,
        if (difficulty >= 0.25) WordQuestionType.matchTranslation,
        if (difficulty >= 0.5) WordQuestionType.missingLetter,
      ];
      final type = types[_rng.nextInt(types.length)];
      switch (type) {
        case WordQuestionType.namePicture:
          return _namePictureHe(difficulty);
        case WordQuestionType.matchTranslation:
          return _matchTranslation(difficulty);
        case WordQuestionType.missingLetter:
          return _missingLetterHe(difficulty);
        case WordQuestionType.correctSpelling:
          // Not used in Hebrew; namePicture is a safe fallback.
          return _namePictureHe(difficulty);
      }
    }
    final types = <WordQuestionType>[
      WordQuestionType.namePicture,
      if (difficulty >= 0.25) WordQuestionType.missingLetter,
      if (difficulty >= 0.5) WordQuestionType.correctSpelling,
    ];
    final type = types[_rng.nextInt(types.length)];
    switch (type) {
      case WordQuestionType.namePicture:
        return _namePicture(difficulty);
      case WordQuestionType.missingLetter:
        return _missingLetter(difficulty);
      case WordQuestionType.correctSpelling:
        return _correctSpelling(difficulty);
      case WordQuestionType.matchTranslation:
        // Not used in English; namePicture is a safe fallback.
        return _namePicture(difficulty);
    }
  }

  WordEntry _pick(double d) {
    final pool = lang == AppLang.he
        ? HebrewWordBank.forDifficulty(d)
        : WordBank.forDifficulty(d);
    return pool[_rng.nextInt(pool.length)];
  }

  // Show emoji, pick the word.
  WordQuestion _namePicture(double d) {
    final answer = _pick(d);
    final options = _distinctWords(d, answer.word, 4);
    return WordQuestion(
      type: WordQuestionType.namePicture,
      prompt: 'Which word is this?',
      emoji: answer.emoji,
      display: '',
      choices: options,
      correctIndex: options.indexOf(answer.word),
      word: answer.word,
    );
  }

  // Hebrew: show emoji, pick the Hebrew word (display form with niqqud).
  WordQuestion _namePictureHe(double d) {
    final answer = _pick(d);
    final options = _distinctDisplayWords(d, answer.displayWord, 4);
    return WordQuestion(
      type: WordQuestionType.namePicture,
      prompt: 'איזו מילה זאת?',
      emoji: answer.emoji,
      display: '',
      choices: options,
      correctIndex: options.indexOf(answer.displayWord),
      word: answer.word,
      translation: answer.translation,
    );
  }

  // Hebrew: show the Hebrew word, pick its English translation.
  WordQuestion _matchTranslation(double d) {
    final answer = _pick(d);
    final pool = HebrewWordBank.forDifficulty(d)
        .map((e) => e.translation)
        .whereType<String>()
        .toList()
      ..shuffle(_rng);
    final set = <String>{answer.translation!};
    for (final t in pool) {
      if (set.length >= 4) break;
      set.add(t);
    }
    if (set.length < 4) {
      final extra = HebrewWordBank.allWords
          .map((e) => e.translation)
          .whereType<String>()
          .toList()
        ..shuffle(_rng);
      for (final t in extra) {
        if (set.length >= 4) break;
        set.add(t);
      }
    }
    final options = set.toList()..shuffle(_rng);
    return WordQuestion(
      type: WordQuestionType.matchTranslation,
      prompt: 'מה הפירוש באנגלית?',
      emoji: answer.emoji,
      display: answer.displayWord,
      choices: options,
      correctIndex: options.indexOf(answer.translation!),
      word: answer.word,
    );
  }

  // Hebrew: show emoji + plain word with a blank; pick the missing letter from
  // the Hebrew alphabet pool (niqqud off, no final forms).
  WordQuestion _missingLetterHe(double d) {
    final entry = _pick(d);
    final word = entry.word;
    // Prefer masking a letter that exists in the choice pool so the correct
    // answer is always offerable; fall back to any index if none qualify.
    final maskable = [
      for (var i = 0; i < word.length; i++)
        if (heAlphabet.contains(word[i])) i,
    ];
    final idx = maskable.isNotEmpty
        ? maskable[_rng.nextInt(maskable.length)]
        : _rng.nextInt(word.length);
    final missing = word[idx];
    final shown =
        [for (var i = 0; i < word.length; i++) i == idx ? '_' : word[i]]
            .join(' ');

    final letters = <String>{missing};
    while (letters.length < 4) {
      letters.add(heAlphabet[_rng.nextInt(heAlphabet.length)]);
    }
    final options = letters.toList()..shuffle(_rng);
    return WordQuestion(
      type: WordQuestionType.missingLetter,
      prompt: 'בחרו את האות החסרה',
      emoji: entry.emoji,
      display: shown,
      choices: options,
      correctIndex: options.indexOf(missing),
      word: word,
      translation: entry.translation,
    );
  }

  // Show emoji + word with a blank; pick the missing letter.
  WordQuestion _missingLetter(double d) {
    final entry = _pick(d);
    final word = entry.word;
    final idx = _rng.nextInt(word.length);
    final missing = word[idx];
    final shown =
        [for (var i = 0; i < word.length; i++) i == idx ? '_' : word[i]]
            .join(' ');

    final letters = <String>{missing};
    const alphabet = 'abcdefghijklmnopqrstuvwxyz';
    while (letters.length < 4) {
      letters.add(alphabet[_rng.nextInt(alphabet.length)]);
    }
    final options = letters.toList()..shuffle(_rng);
    return WordQuestion(
      type: WordQuestionType.missingLetter,
      prompt: 'Pick the missing letter',
      emoji: entry.emoji,
      display: shown,
      choices: options,
      correctIndex: options.indexOf(missing),
      word: word,
    );
  }

  // Show emoji; pick the correctly spelled word among misspellings.
  WordQuestion _correctSpelling(double d) {
    final entry = _pick(d);
    final correct = entry.word;
    final options = <String>{correct};
    var guard = 0;
    while (options.length < 4 && guard < 40) {
      guard++;
      options.add(_misspell(correct));
    }
    // Top up if needed.
    var n = 1;
    while (options.length < 4) {
      options.add('$correct${'x' * n}');
      n++;
    }
    final list = options.toList()..shuffle(_rng);
    return WordQuestion(
      type: WordQuestionType.correctSpelling,
      prompt: 'Which spelling is correct?',
      emoji: entry.emoji,
      display: '',
      choices: list,
      correctIndex: list.indexOf(correct),
      word: correct,
    );
  }

  /// Creates a plausible misspelling by swapping, doubling, or dropping a
  /// letter.
  String _misspell(String word) {
    if (word.length < 2) return '${word}e';
    final chars = word.split('');
    final op = _rng.nextInt(3);
    final i = _rng.nextInt(chars.length);
    switch (op) {
      case 0: // swap two adjacent letters
        final j = (i + 1) % chars.length;
        final tmp = chars[i];
        chars[i] = chars[j];
        chars[j] = tmp;
        break;
      case 1: // double a letter
        chars.insert(i, chars[i]);
        break;
      default: // change a vowel
        const vowels = 'aeiou';
        chars[i] = vowels[_rng.nextInt(vowels.length)];
    }
    final result = chars.join();
    return result == word ? '${word}e' : result;
  }

  // Distinct Hebrew display words (niqqud forms) for namePicture choices.
  List<String> _distinctDisplayWords(double d, String answer, int count) {
    final pool =
        HebrewWordBank.forDifficulty(d).map((e) => e.displayWord).toList();
    final set = <String>{answer};
    pool.shuffle(_rng);
    for (final w in pool) {
      if (set.length >= count) break;
      set.add(w);
    }
    if (set.length < count) {
      final extra =
          HebrewWordBank.allWords.map((e) => e.displayWord).toList()
            ..shuffle(_rng);
      for (final w in extra) {
        if (set.length >= count) break;
        set.add(w);
      }
    }
    return set.toList()..shuffle(_rng);
  }

  List<String> _distinctWords(double d, String answer, int count) {
    final pool = WordBank.forDifficulty(d).map((e) => e.word).toList();
    final set = <String>{answer};
    pool.shuffle(_rng);
    for (final w in pool) {
      if (set.length >= count) break;
      set.add(w);
    }
    if (set.length < count) {
      final extra = WordBank.allWords.map((e) => e.word).toList()
        ..shuffle(_rng);
      for (final w in extra) {
        if (set.length >= count) break;
        set.add(w);
      }
    }
    return set.toList()..shuffle(_rng);
  }
}
