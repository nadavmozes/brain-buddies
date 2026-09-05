import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: paper,
      ),
      scaffoldBackgroundColor: paper,
    );

    return base.copyWith(
      textTheme: GoogleFonts.baloo2TextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
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
