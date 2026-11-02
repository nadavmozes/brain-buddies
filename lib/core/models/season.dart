import 'package:flutter/material.dart';

/// The four (culturally NEUTRAL) seasons used for the hub's subtle, date-driven
/// dressing. Selection is derived purely from the current month (see
/// [Season.forDate]) and NEVER persisted — it mirrors the deterministic,
/// date-only style of `Missions.forDay`, so a pure selector is unit-testable
/// without mocking the clock.
enum Season {
  winter,
  spring,
  summer,
  autumn;

  /// Maps a date's month to a season (culturally neutral grouping):
  /// 12,1,2 = winter; 3,4,5 = spring; 6,7,8 = summer; 9,10,11 = autumn.
  /// Date-only + deterministic (mirrors `Missions.forDay`), so pure selectors
  /// are unit-testable without mocking the clock. NO persistence.
  static Season forDate(DateTime d) {
    switch (d.month) {
      case 12:
      case 1:
      case 2:
        return Season.winter;
      case 3:
      case 4:
      case 5:
        return Season.spring;
      case 6:
      case 7:
      case 8:
        return Season.summer;
      default: // 9, 10, 11
        return Season.autumn;
    }
  }
}

/// Data for each [Season]: a stable [key] (the enum name, used for frame
/// gating + localization), a small [emoji] motif, and a SUBTLE accent [tint]
/// blended lightly into the hub background.
extension SeasonInfo on Season {
  /// The stable key (the enum name) — used as the frame-gate id and the
  /// localization key for [AppStrings.seasonName].
  String get key => name;

  /// A small, friendly seasonal emoji motif shown once near the hub title.
  String get emoji {
    switch (this) {
      case Season.winter:
        return '❄️';
      case Season.spring:
        return '🌸';
      case Season.summer:
        return '☀️';
      case Season.autumn:
        return '🍂';
    }
  }

  /// A subtle accent color per season, blended lightly into the hub gradient.
  Color get tint {
    switch (this) {
      case Season.winter:
        return const Color(0xFFBBDEFB); // pale blue
      case Season.spring:
        return const Color(0xFFF8BBD0); // pale pink
      case Season.summer:
        return const Color(0xFFFFE082); // warm amber
      case Season.autumn:
        return const Color(0xFFFFCC80); // soft orange
    }
  }
}
