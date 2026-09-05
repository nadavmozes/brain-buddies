import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The moods the hero buddy can display.
enum BuddyMood { idle, happy, sad }

/// A friendly comic-style hero face that reacts to the player's answers.
///
/// Drawn entirely with widgets (no image assets required) so it works
/// out of the box. Swap in an image or Rive/Lottie later if desired.
class HeroBuddy extends StatelessWidget {
  const HeroBuddy({
    super.key,
    required this.mood,
    this.size = 96,
    this.heroEmoji,
    this.baseColor,
  });

  final BuddyMood mood;
  final double size;

  /// The equipped hero's emoji, shown when idle. Defaults to 🦸.
  final String? heroEmoji;

  /// The equipped hero's color, used for the idle face.
  final Color? baseColor;

  Color get _faceColor {
    switch (mood) {
      case BuddyMood.happy:
        return AppTheme.success;
      case BuddyMood.sad:
        return AppTheme.danger;
      case BuddyMood.idle:
        return baseColor ?? AppTheme.primary;
    }
  }

  String get _emoji {
    switch (mood) {
      case BuddyMood.happy:
        return '😄';
      case BuddyMood.sad:
        return '😲';
      case BuddyMood.idle:
        return heroEmoji ?? '🦸';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: mood == BuddyMood.happy ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _faceColor,
          shape: BoxShape.circle,
          border: AppTheme.comicBorder,
          boxShadow: AppTheme.comicShadow(offset: 4),
        ),
        child: Text(_emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}
