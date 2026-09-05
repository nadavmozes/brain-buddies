import 'dart:math';

import '../models/word_bank.dart';
import '../models/word_question.dart';

/// Generates Word Wizard questions. [difficulty] 0..1 selects the word pool
/// and mixes in harder question types.
class WordQuestionGenerator {
  WordQuestionGenerator({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  List<WordQuestion> generateRound(int count, {double difficulty = 0.3}) {
    return List.generate(count, (i) {
      final d = (difficulty + i / (count * 2)).clamp(0.0, 1.0);
      return generateOne(d);
    });
  }

  WordQuestion generateOne(double difficulty) {
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
    }
  }

  WordEntry _pick(double d) {
    final pool = WordBank.forDifficulty(d);
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
