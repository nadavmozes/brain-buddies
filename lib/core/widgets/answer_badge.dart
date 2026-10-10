import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small comic chip that marks an answered tile with a check (correct) or a
/// cross (wrong).
///
/// This is an ADDITIONAL, non-color channel layered over the existing tile
/// color fills and sound effects. Red/green color-blind kids can rely on the
/// icon shape (✓ vs ✕) instead of the green/red fill, so the correctness cue
/// never depends on color alone.
class AnswerBadge extends StatelessWidget {
  const AnswerBadge({
    super.key,
    required this.show,
    required this.correct,
  });

  /// Whether to render the badge at all (false until the tile is answered).
  final bool show;

  /// True renders a check on an [AppTheme.success] fill; false renders a cross
  /// on an [AppTheme.danger] fill.
  final bool correct;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: correct ? AppTheme.success : AppTheme.danger,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.ink, width: 2.5),
        boxShadow: AppTheme.comicShadow(offset: 2),
      ),
      child: Icon(
        correct ? Icons.check_rounded : Icons.close_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
