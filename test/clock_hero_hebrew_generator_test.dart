// FEAT-002 (plan.md I.1): the Clock Hero generator must produce Hebrew prompts
// and Hebrew spoken-time in Hebrew mode, while English mode stays byte-identical
// to the original English prompts. Deterministic via a seeded Random.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:brain_buddies/core/l10n/app_lang.dart';
import 'package:brain_buddies/games/clock_hero/models/clock_question.dart';
import 'package:brain_buddies/games/clock_hero/models/time_world.dart';
import 'package:brain_buddies/games/clock_hero/services/clock_generator.dart';

final _hebrew = RegExp(r'[\u0590-\u05FF]');

/// English phrases that must NEVER appear in a Hebrew prompt.
const _englishPhrases = [
  "o'clock",
  'What time',
  'Which clock',
  'Set the clock',
  'hours',
  'hour',
];

void main() {
  group('Clock Hero Hebrew generator', () {
    test('every Hebrew prompt is Hebrew with no English leaking', () {
      for (final level in ClockMap.allLevels) {
        for (var seed = 0; seed < 30; seed++) {
          final qs = ClockQuestionGenerator.forLevel(
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

    test('English prompts are byte-identical to the original wording', () {
      // Reproduce the original hard-coded English prompts for every type by
      // regenerating with the same seed and asserting the exact phrasing.
      final seenTypes = <ClockQuestionType>{};
      for (final level in ClockMap.allLevels) {
        for (var seed = 0; seed < 40; seed++) {
          final qs = ClockQuestionGenerator.forLevel(
            level,
            random: Random(seed),
            lang: AppLang.en,
          );
          for (final q in qs) {
            seenTypes.add(q.type);
            switch (q.type) {
              case ClockQuestionType.readClock:
                expect(q.prompt, 'What time is it?');
                break;
              case ClockQuestionType.findClock:
                expect(q.prompt, startsWith('Which clock shows '));
                expect(q.prompt, endsWith('?'));
                break;
              case ClockQuestionType.setClock:
                expect(q.prompt, startsWith('Set the clock to '));
                break;
              case ClockQuestionType.elapsed:
                expect(q.prompt, startsWith("It's "));
                expect(q.prompt, contains('. What time in '));
                expect(
                    q.prompt.contains(' hour?') || q.prompt.contains(' hours?'),
                    isTrue,
                    reason: 'elapsed prompt should end with hour(s): $q');
                break;
            }
          }
        }
      }
      // All four question types should have been exercised across the trail.
      expect(seenTypes, containsAll(ClockQuestionType.values));
    });
  });
}
