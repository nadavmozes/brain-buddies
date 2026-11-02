// Engagement Phase 5 — P7 Seasonal themes. Locks in the pure, date-driven
// Season selector (no persistence), its keys/emojis, and the localized season
// names (English + Hebrew).

import 'package:brain_buddies/core/l10n/app_strings.dart';
import 'package:brain_buddies/core/models/season.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Season.forDate maps every month', () {
    // month -> expected season (12,1,2 winter; 3,4,5 spring; 6,7,8 summer;
    // 9,10,11 autumn).
    const expected = <int, Season>{
      1: Season.winter,
      2: Season.winter,
      3: Season.spring,
      4: Season.spring,
      5: Season.spring,
      6: Season.summer,
      7: Season.summer,
      8: Season.summer,
      9: Season.autumn,
      10: Season.autumn,
      11: Season.autumn,
      12: Season.winter,
    };

    for (var m = 1; m <= 12; m++) {
      test('month $m -> ${expected[m]}', () {
        expect(Season.forDate(DateTime(2024, m, 15)), expected[m]);
      });
    }

    test('covers all four seasons across the year', () {
      final seen = <Season>{
        for (var m = 1; m <= 12; m++) Season.forDate(DateTime(2024, m, 1)),
      };
      expect(seen, Season.values.toSet());
    });
  });

  group('season keys + emojis', () {
    test('keys are the enum names', () {
      expect(Season.winter.key, 'winter');
      expect(Season.spring.key, 'spring');
      expect(Season.summer.key, 'summer');
      expect(Season.autumn.key, 'autumn');
    });

    test('emojis are the four expected motifs', () {
      expect(Season.winter.emoji, '❄️');
      expect(Season.spring.emoji, '🌸');
      expect(Season.summer.emoji, '☀️');
      expect(Season.autumn.emoji, '🍂');
    });
  });

  group('seasonName localization', () {
    test('English names', () {
      const en = EnStrings();
      expect(en.seasonName('winter'), 'Winter');
      expect(en.seasonName('spring'), 'Spring');
      expect(en.seasonName('summer'), 'Summer');
      expect(en.seasonName('autumn'), 'Autumn');
    });

    test('Hebrew names', () {
      const he = HeStrings();
      expect(he.seasonName('winter'), 'חורף');
      expect(he.seasonName('spring'), 'אביב');
      expect(he.seasonName('summer'), 'קיץ');
      expect(he.seasonName('autumn'), 'סתיו');
    });
  });
}
