// Unit tests for the Money Math 'make change' question type.
//
// Verifies that the Vault world can produce makeChange questions with a valid,
// non-negative correct answer, and that non-Vault worlds never produce them.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:brain_buddies/games/money_math/models/money_level.dart';
import 'package:brain_buddies/games/money_math/models/money_question.dart';
import 'package:brain_buddies/games/money_math/services/money_generator.dart';

void main() {
  test('Vault rounds can produce a valid makeChange question', () {
    final vaultLevels = MoneyMap.trail(MoneyWorld.vault).levels;

    var sawMakeChange = false;
    // Seed deterministically; sweep seeds + levels to reliably hit makeChange.
    for (var seed = 0; seed < 50 && !sawMakeChange; seed++) {
      for (final level in vaultLevels) {
        final questions =
            MoneyQuestionGenerator.forLevel(level, random: Random(seed));
        for (final q in questions) {
          if (q.type != MoneyQuestionType.makeChange) continue;
          sawMakeChange = true;

          final choices = q.textChoices;
          expect(choices, isNotNull,
              reason: 'makeChange must use text choices');
          expect(q.correctIndex, inInclusiveRange(0, choices!.length - 1));

          // The correct choice parses to a non-negative cent amount.
          final correctLabel = choices[q.correctIndex];
          final correctCents =
              int.parse(correctLabel.replaceAll('¢', '').trim());
          expect(correctCents, greaterThanOrEqualTo(0));

          // The correct value is actually present among the shown choices.
          expect(choices.contains(correctLabel), isTrue);
        }
      }
    }

    expect(sawMakeChange, isTrue,
        reason: 'Vault world should surface makeChange questions');
  });

  test('non-Vault worlds never produce makeChange', () {
    for (final world in MoneyWorld.values) {
      if (world == MoneyWorld.vault) continue;
      for (final level in MoneyMap.trail(world).levels) {
        for (var seed = 0; seed < 50; seed++) {
          final questions =
              MoneyQuestionGenerator.forLevel(level, random: Random(seed));
          for (final q in questions) {
            expect(q.type, isNot(MoneyQuestionType.makeChange),
                reason: '${world.name} must not produce makeChange');
          }
        }
      }
    }
  });
}
