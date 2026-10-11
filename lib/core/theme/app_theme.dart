import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_lang.dart';

/// Comic-book inspired palette and theme for the whole app.
class AppTheme {
  AppTheme._();

  // Core palette
  static const Color ink = Color(0xFF1A1A2E); // heavy comic outline
  static const Color paper = Color(0xFFFFF6E5); // warm comic paper
  static const Color primary = Color(0xFF6C63FF); // hero purple
  static const Color accent = Color(0xFFFFD23F); // pow yellow
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color sky = Color(0xFF4FC3F7);

  // Boss/guardian "encounter bar" backgrounds. Kept as distinct per-game tones
  // (purple for Number Quest's boss, blue-slate for Shape Safari's guardian)
  // but named here so the values live in one place.
  static const Color bossBar = Color(0xFF4A3A6E); // Number Quest boss bar
  static const Color guardianBar = Color(0xFF3E4E63); // Shape Safari guardian

  /// Builds the app theme for [lang].
  ///
  /// English keeps the original rounded display font (Baloo 2). Hebrew uses
  /// **Fredoka** — a friendly, rounded Google Font that ships a Hebrew subset
  /// (Baloo 2 does not reliably cover Hebrew and would render as tofu). In both
  /// cases a Hebrew-capable fallback (Heebo) is set so mixed EN/HE text and any
  /// stray glyphs degrade gracefully instead of showing boxes.
  static ThemeData build([AppLang lang = AppLang.en]) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: paper,
      ),
      scaffoldBackgroundColor: paper,
    );

    // The Hebrew-capable fallback chain. Heebo covers Hebrew; Baloo 2 keeps the
    // Latin/emoji feel consistent when a glyph is missing from the base family.
    final hebrewFallback = <String>[
      GoogleFonts.heebo().fontFamily!,
      GoogleFonts.baloo2().fontFamily!,
    ];

    final baseTextTheme = lang == AppLang.he
        ? GoogleFonts.fredokaTextTheme(base.textTheme)
        : GoogleFonts.baloo2TextTheme(base.textTheme);

    return base.copyWith(
      textTheme: baseTextTheme
          .apply(
            bodyColor: ink,
            displayColor: ink,
            fontFamilyFallback: hebrewFallback,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: ink,
      ),
    );
  }

  /// A thick black comic-style border.
  static Border get comicBorder =>
      Border.all(color: ink, width: 3.5);

  /// The signature hard drop shadow used on comic panels.
  static List<BoxShadow> comicShadow({Color color = ink, double offset = 5}) {
    return [
      BoxShadow(
        color: color,
        offset: Offset(offset, offset),
        blurRadius: 0,
      ),
    ];
  }
}
