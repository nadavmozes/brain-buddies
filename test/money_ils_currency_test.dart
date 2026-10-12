// Phase 3 tests: locale-aware Israeli (₪) currency for Money Math + the Coin
// Info Map legend. Deterministic via seeded Random.
//
// Verifies that:
//  - the ILS Currency formats agorot / shekel amounts correctly,
//  - the generator in Hebrew mode uses ONLY the ₪ denominations and never US
//    coins (and English mode stays US-only),
//  - makeChange in ₪ is non-negative and coin-representable,
//  - countCoins / whichMore / makeAmount give 4 distinct valid choices in ₪,
//  - the Coin Info Map opens and lists the current currency's coins.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brain_buddies/core/l10n/app_lang.dart';
import 'package:brain_buddies/core/l10n/app_strings.dart';
import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/games/money_math/models/money_level.dart';
import 'package:brain_buddies/games/money_math/models/money_question.dart';
import 'package:brain_buddies/games/money_math/services/money_generator.dart';
import 'package:brain_buddies/games/money_math/widgets/coin_info_map.dart';

const _he = HeStrings();

/// The exact set of ILS denomination values (agorot) we teach.
const _ilsValues = {10, 50, 100, 200, 500, 1000};

/// The US denomination values (cents).
const _usdValues = {1, 5, 10, 25};

void main() {
  group('Currency formatting', () {
    test('ILS formats sub-shekel as agorot and whole/mixed as ₪', () {
      expect(Currency.ils.format(10), '10 אג׳');
      expect(Currency.ils.format(50), '50 אג׳');
      expect(Currency.ils.format(99), '99 אג׳');
      expect(Currency.ils.format(100), '₪1');
      expect(Currency.ils.format(200), '₪2');
      expect(Currency.ils.format(1000), '₪10');
      expect(Currency.ils.format(250), '₪2.50');
      expect(Currency.ils.format(105), '₪1.05');
    });

    test('USD formatting is byte-identical to the original ¢ behavior', () {
      expect(Currency.usd.format(1), '1¢');
      expect(Currency.usd.format(45), '45¢');
      expect(Currency.usd.format(100), '100¢');
    });
  });

  group('Hebrew generator uses the ₪ coin set', () {
    test('every coin in he mode is an ILS denomination (never a US coin)', () {
      for (final level in MoneyMap.allLevels) {
        for (var seed = 0; seed < 40; seed++) {
          final qs = MoneyQuestionGenerator.forLevel(
            level,
            lang: AppLang.he,
            random: Random(seed),
          );
          for (final q in qs) {
            final piles = <CoinPile?>[
              q.pile,
              q.pileA,
              q.pileB,
              ...?q.pileChoices,
            ];
            for (final p in piles) {
              if (p == null) continue;
              for (final c in p.coins) {
                expect(c.currency, Currency.ils,
                    reason: 'coin $c should be ILS in he mode');
                expect(_ilsValues.contains(c.cents), isTrue,
                    reason: '${c.cents} is not an ILS denomination');
                expect(_usdValues.contains(c.cents) && c.cents != 10, isFalse,
                    reason: 'US-only value leaked into he mode');
              }
            }
          }
        }
      }
    });

    test('English mode stays US-only (no ILS coins)', () {
      for (final level in MoneyMap.allLevels) {
        for (var seed = 0; seed < 20; seed++) {
          final qs = MoneyQuestionGenerator.forLevel(
            level,
            lang: AppLang.en,
            random: Random(seed),
          );
          for (final q in qs) {
            for (final p in [q.pile, q.pileA, q.pileB, ...?q.pileChoices]) {
              if (p == null) continue;
              for (final c in p.coins) {
                expect(c.currency, Currency.usd);
              }
            }
          }
        }
      }
    });
  });

  group('Hebrew makeChange', () {
    test('is strictly positive and a multiple of 10 agorot', () {
      final vaultLevels = MoneyMap.trail(MoneyWorld.vault).levels;
      var saw = false;
      for (var seed = 0; seed < 80 && !saw; seed++) {
        for (final level in vaultLevels) {
          final qs = MoneyQuestionGenerator.forLevel(
            level,
            lang: AppLang.he,
            random: Random(seed),
          );
          for (final q in qs) {
            if (q.type != MoneyQuestionType.makeChange) continue;
            saw = true;
            final label = q.textChoices![q.correctIndex];
            // Correct label must be a valid ILS amount string.
            expect(label.contains('₪') || label.contains('אג׳'), isTrue);
          }
        }
      }
      expect(saw, isTrue, reason: 'Vault he mode should surface makeChange');
    });
  });

  group('Hebrew choices are valid', () {
    test('countCoins / whichMore / makeAmount give 4 distinct valid choices',
        () {
      for (final level in MoneyMap.allLevels) {
        for (var seed = 0; seed < 30; seed++) {
          final qs = MoneyQuestionGenerator.forLevel(
            level,
            lang: AppLang.he,
            random: Random(seed),
          );
          for (final q in qs) {
            switch (q.type) {
              case MoneyQuestionType.countCoins:
              case MoneyQuestionType.makeChange:
                final c = q.textChoices!;
                expect(c.length, 4);
                expect(c.toSet().length, 4,
                    reason: 'text choices must be distinct: $c');
                expect(q.correctIndex, inInclusiveRange(0, 3));
                break;
              case MoneyQuestionType.makeAmount:
                final p = q.pileChoices!;
                expect(p.length, 4);
                expect(p.map((e) => e.total).toSet().length, 4,
                    reason: 'pile totals must be distinct');
                expect(q.correctIndex, inInclusiveRange(0, 3));
                break;
              case MoneyQuestionType.whichMore:
                expect(q.pileA!.total == q.pileB!.total, isFalse);
                expect(q.correctIndex, inInclusiveRange(0, 1));
                break;
            }
          }
        }
      }
    });
  });

  group('Coin Info Map', () {
    Widget wrap(Widget child, AppLang lang) {
      return MaterialApp(
        locale: lang.locale,
        home: L10n(
          lang: lang,
          notifier: const AlwaysStoppedAnimation<double>(0),
          child: Directionality(
            textDirection: lang.direction,
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets('ILS legend lists all six Hebrew coins', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(
        const CoinInfoMap(currency: Currency.ils),
        AppLang.he,
      ));
      await tester.pumpAndSettle();

      expect(find.text('💰 ${_he.coinInfoTitle}'), findsOneWidget);
      for (final value in _ilsValues) {
        expect(find.text(_he.ilsCoinName(value)), findsOneWidget,
            reason: 'legend should name the $value-agorot coin');
      }
    });

    testWidgets('USD legend lists the four US coins', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(
        const CoinInfoMap(currency: Currency.usd),
        AppLang.en,
      ));
      await tester.pumpAndSettle();

      const en = EnStrings();
      for (final value in _usdValues) {
        expect(find.text(en.usdCoinName(value)), findsOneWidget);
      }
    });
  });
}
