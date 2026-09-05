import 'package:flutter/services.dart';

import 'sound_bridge.dart';

/// Feedback for game events: synthesized sound effects (on web) plus haptics
/// and OS system sounds (on native). When [enabled] is false, all calls are
/// no-ops so the settings toggle takes effect immediately.
class FeedbackService {
  const FeedbackService({required this.enabled});

  final bool enabled;

  /// A light tap sound, e.g. selecting an answer or pressing a button.
  void click() {
    if (!enabled) return;
    SoundBridge.click();
    HapticFeedback.selectionClick();
  }

  /// Positive feedback for a correct answer.
  void correct() {
    if (!enabled) return;
    SoundBridge.correct();
    HapticFeedback.lightImpact();
  }

  /// Negative feedback for a wrong answer.
  void wrong() {
    if (!enabled) return;
    SoundBridge.wrong();
    HapticFeedback.heavyImpact();
  }

  /// A coin/sparkle sound for earning rewards.
  void coin() {
    if (!enabled) return;
    SoundBridge.coin();
    HapticFeedback.selectionClick();
  }

  /// A rising jingle for leveling up.
  void levelUp() {
    if (!enabled) return;
    SoundBridge.levelUp();
    HapticFeedback.mediumImpact();
  }

  /// A victory fanfare for finishing a quest strongly or beating a boss.
  void celebrate() {
    if (!enabled) return;
    SoundBridge.victory();
    HapticFeedback.mediumImpact();
  }
}
