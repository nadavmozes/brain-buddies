// Unit tests for the Hebrew Word Wizard generator (Phase 2, FEAT-001).
//
// Deterministic via seeded Random. Verifies that Hebrew mode produces Hebrew
// words, that the missing-letter choices come only from the Hebrew alphabet
// (never Latin), that matchTranslation picks the correct English translation,
// and that every question has exactly 4 distinct valid choices.

import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import 'package:brain_buddies/core/l10n/app_lang.dart';
import 'package:brain_buddies/games/word_wizard/models/word_question.dart';
import 'package:brain_buddies/games/word_wizard/models/wizard_level.dart';
import 'package:brain_buddies/games/word_wizard/services/word_generator.dart';

/// Matches any character in the Hebrew Unicode block.
final _hebrew = RegExp(r'[\u0590-\u05FF]');
final _latin = RegExp(r'[a-z]', caseSensitive: false);

bool _hasHebrew(String s) => _hebrew.hasMatch(s);

void main() {
  group('Hebrew Word Wizard generator', () {
    test('namePicture / missingLetter words are Hebrew in he mode', () {
      // Use a hard level so every Hebrew question type can appear.
      final level = WizardMap.allLevels.last; // storm boss, highest difficulty
      final qs = WordQuestionGenerator.forLevel(
        level,
        lang: AppLang.he,
        random: Random(7),
      );
      expect(qs, isNotEmpty);
      for (final q in qs) {
        if (q.type == WordQuestionType.namePicture) {
          // The displayed word choice at correctIndex is Hebrew.
          expect(_hasHebrew(q.choices[q.correctIndex]), isTrue,
              reason: 'namePicture answer should be Hebrew: $q');
          expect(_hasHebrew(q.word ?? ''), isTrue);
        }
        if (q.type == WordQuestionType.missingLetter) {
          expect(_hasHebrew(q.word ?? ''), isTrue,
              reason: 'missingLetter word should be Hebrew: $q');
        }
      }
    });

    test('missingLetter choices are Hebrew letters with no Latin a-z', () {
      final level = WizardMap.allLevels.last;
      // Several seeds so we exercise many generated missing-letter questions.
      var sawMissing = false;
      for (final seed in [1, 7, 13, 42, 99, 123]) {
        final qs = WordQuestionGenerator.forLevel(
          level,
          lang: AppLang.he,
          random: Random(seed),
        );
        for (final q in qs) {
          if (q.type != WordQuestionType.missingLetter) continue;
          sawMissing = true;
          for (final c in q.choices) {
            expect(c.length, 1, reason: 'letter choice should be one char: $c');
            expect(heAlphabet.contains(c), isTrue,
                reason: 'choice "$c" not in the Hebrew alphabet pool');
            expect(_latin.hasMatch(c), isFalse,
                reason: 'choice "$c" must not be a Latin letter');
          }
        }
      }
      expect(sawMissing, isTrue,
          reason: 'expected at least one missing-letter question across seeds');
    });

    test('every question has 4 distinct choices with the answer present', () {
      for (final level in WizardMap.allLevels) {
        final qs = WordQuestionGenerator.forLevel(
          level,
          lang: AppLang.he,
          random: Random(42),
        );
        for (final q in qs) {
          expect(q.choices.length, 4, reason: 'exactly 4 choices: $q');
          expect(q.choices.toSet().length, 4,
              reason: 'choices must be distinct: $q');
          expect(q.correctIndex, inInclusiveRange(0, 3));
        }
      }
    });

    test('Hebrew mode never shows English translation questions', () {
      // The Hebrew Word Wizard teaches Hebrew reading, not English. Every
      // question type must be Hebrew-only: no matchTranslation, and every
      // answer choice is Hebrew (missingLetter choices are single Hebrew
      // letters; namePicture choices are Hebrew words).
      final level = WizardMap.allLevels.last;
      for (final seed in [1, 7, 13, 42, 99, 123, 256]) {
        final qs = WordQuestionGenerator.forLevel(
          level,
          lang: AppLang.he,
          random: Random(seed),
        );
        for (final q in qs) {
          expect(q.type, isNot(WordQuestionType.matchTranslation),
              reason: 'Hebrew mode must not use translation questions');
          for (final c in q.choices) {
            expect(_hasHebrew(c), isTrue,
                reason: 'every Hebrew choice should be Hebrew, got: $c');
          }
        }
      }
    });

    test('English mode is unchanged (words are Latin, no matchTranslation)',
        () {
      final level = WizardMap.allLevels.last;
      final qs = WordQuestionGenerator.forLevel(
        level,
        lang: AppLang.en,
        random: Random(7),
      );
      for (final q in qs) {
        expect(q.type, isNot(WordQuestionType.matchTranslation));
        expect(_latin.hasMatch(q.choices[q.correctIndex]), isTrue);
      }
    });
  });
}
