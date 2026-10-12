import 'package:flutter/widgets.dart';

/// The two languages BrainBuddies supports: English and Hebrew.
///
/// Hebrew (`he`) is a right-to-left language, so [direction]/[isRtl] drive the
/// app-wide [Directionality] via `MaterialApp.locale`.
enum AppLang {
  en,
  he;

  /// The Flutter [Locale] for this language.
  Locale get locale => switch (this) {
        AppLang.en => const Locale('en'),
        AppLang.he => const Locale('he'),
      };

  /// Reading direction for this language.
  TextDirection get direction =>
      this == AppLang.he ? TextDirection.rtl : TextDirection.ltr;

  /// Whether this language reads right-to-left.
  bool get isRtl => this == AppLang.he;

  /// The persisted string code used in shared_preferences.
  String get code => name;

  /// Resolves a persisted code back to an [AppLang] (defaults to English).
  static AppLang fromCode(String? code) =>
      code == AppLang.he.code ? AppLang.he : AppLang.en;

  /// Maps a platform/device [Locale] to a supported language. Any locale whose
  /// language code is Hebrew (`he`, or the legacy `iw`) becomes [AppLang.he];
  /// everything else defaults to [AppLang.en] so existing/English users and the
  /// test environment (en_US) stay on English.
  static AppLang fromLocale(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    return (code == 'he' || code == 'iw') ? AppLang.he : AppLang.en;
  }
}
