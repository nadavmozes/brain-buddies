import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A full-width celebratory banner used on result screens (e.g. "NEW BEST
/// SCORE!"). Comic-styled: primary fill, thick ink border, white centered text.
class ResultBanner extends StatelessWidget {
  const ResultBanner(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ink, width: 2.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
      ),
    );
  }
}
