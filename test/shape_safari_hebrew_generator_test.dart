// FEAT-002 (plan.md I.2): the Shape Safari generator must produce Hebrew prompts
// and Hebrew shape names in its choices in Hebrew mode, while English mode stays
// byte-identical to the original English prompts. Deterministic via a seeded
// Random.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:brain_buddies/core/l10n/app_lang.dart';
import 'package:brain_buddies/games/shape_safari/models/safari_level.dart';
import 'package:brain_buddies/games/shape_safari/models/shape_question.dart';
import 'package:brain_buddies/games/shape_safari/services/question_generator.dart';

final _hebrew = RegExp(r'[\u0590-\u05FF]');

/// English prompt phrases that must NEVER appear in a Hebrew prompt.
const _englishPhrases = [
  'What shape',
  'Which one',
  'How many sides',
  'What comes next',
];

/// A few Hebrew shape names from the ss.shape.label domain.
const _hebrewShapeNames = ['עיגול', 'ריבוע', 'משולש', 'מלבן', 'כוכב'];

void main() {
  group('Shape Safari Hebrew generator', () {
    test('every Hebrew prompt is Hebrew with no English leaking', () {
      for (final level in SafariMap.allLevels) {
        for (var seed = 0; seed < 30; seed++) {
          final qs = ShapeQuestionGenerator.forLevel(
            level,
            random: Random(seed),
            lang: AppLang.he,
          );
          for (final q in qs) {
            expect(_hebrew.hasMatch(q.prompt), isTrue,
                reason: 'prompt should contain Hebrew: "${q.prompt}"');
            for (final phrase in _englishPhrases) {
              expect(q.prompt.contains(phrase), isFalse,
                  reason: 'English "$phrase" leaked into: "${q.prompt}"');
            }
          }
        }
      }
    });

    test('at least one identify question shows Hebrew shape-name choices', () {
      var sawHebrewChoice = false;
      for (final level in SafariMap.allLevels) {
        for (var seed = 0; seed < 40 && !sawHebrewChoice; seed++) {
          final qs = ShapeQuestionGenerator.forLevel(
            level,
            random: Random(seed),
            lang: AppLang.he,
          );
          for (final q in qs) {
            if (q.type != ShapeQuestionType.identify) continue;
            for (final c in q.choices) {
              // Identify choices are text (the shape name).
              if (c.text != null && _hebrew.hasMatch(c.text!)) {
                sawHebrewChoice = true;
              }
              if (c.text != null &&
                  _hebrewShapeNames.contains(c.text)) {
                sawHebrewChoice = true;
              }
            }
          }
        }
      }
      expect(sawHebrewChoice, isTrue,
          reason: 'identify choices should contain a Hebrew shape name');
    });

    test('English prompts are byte-identical to the original wording', () {
      final seenTypes = <ShapeQuestionType>{};
      for (final level in SafariMap.allLevels) {
        for (var seed = 0; seed < 40; seed++) {
          final qs = ShapeQuestionGenerator.forLevel(
            level,
            random: Random(seed),
            lang: AppLang.en,
          );
          for (final q in qs) {
            seenTypes.add(q.type);
            switch (q.type) {
              case ShapeQuestionType.identify:
                expect(q.prompt, 'What shape is this?');
                break;
              case ShapeQuestionType.find:
                expect(q.prompt, startsWith('Which one is a '));
                expect(q.prompt, endsWith('?'));
                break;
              case ShapeQuestionType.countSides:
                expect(q.prompt, 'How many sides does this shape have?');
                break;
              case ShapeQuestionType.pattern:
                expect(q.prompt, 'What comes next?');
                break;
            }
          }
        }
      }
      expect(seenTypes, containsAll(ShapeQuestionType.values));
    });
  });
}
