import 'package:flutter/material.dart';

import '../models/avatar.dart';
import '../models/avatar_frame.dart';
import '../theme/app_theme.dart';

/// Renders an avatar's emoji inside its colored circle, with an OPTIONAL
/// decorative ring (an [AvatarFrame]) drawn OUTSIDE the circle so the avatar
/// itself never shrinks.
///
/// Shared by the hub profile bar, the avatar picker, and the shop so all three
/// sites draw frames identically. The ring is radially symmetric, so it is
/// RTL-safe.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.avatar,
    required this.frame,
    this.size = 44,
    this.emojiSize = 24,
    this.circleBorderWidth = 2.5,
    this.highlight = false,
  });

  /// The avatar whose color + emoji are drawn.
  final Avatar avatar;

  /// The frame whose ring is drawn around the circle. Pass
  /// `AvatarFrames.byId('none')` (or a frame with [AvatarFrame.hasRing] false)
  /// for no ring.
  final AvatarFrame frame;

  /// Diameter of the inner avatar circle (the ring sits outside this).
  final double size;

  /// Font size of the avatar emoji.
  final double emojiSize;

  /// Width of the circle's own ink border.
  final double circleBorderWidth;

  /// When true, the circle border uses the success color + a thicker stroke
  /// (used by the picker to mark the equipped avatar). Independent of the
  /// decorative frame ring.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    // Gap between the circle's ink border and the decorative ring, so the ring
    // reads as a separate band rather than thickening the border.
    const gap = 2.0;
    final hasRing = frame.hasRing;
    final ringWidth = hasRing ? frame.ringWidth : 0.0;
    // Total footprint grows OUTWARD by the ring + gap on every side, so the
    // inner [size] circle (and the emoji) is never shrunk by the frame.
    final outer = size + (hasRing ? (gap + ringWidth) * 2 : 0);

    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatar.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: highlight ? AppTheme.success : AppTheme.ink,
          width: highlight ? 4 : circleBorderWidth,
        ),
      ),
      child: Text(avatar.emoji, style: TextStyle(fontSize: emojiSize)),
    );

    if (!hasRing) {
      return SizedBox(width: outer, height: outer, child: Center(child: circle));
    }

    return SizedBox(
      width: outer,
      height: outer,
      child: Container(
        padding: EdgeInsets.all(ringWidth + gap),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // A thin ink outline keeps the comic style around the ring.
          border: Border.all(color: AppTheme.ink, width: 1.5),
          gradient: frame.gradient != null
              ? SweepGradient(colors: frame.gradient!)
              : null,
          color: frame.gradient == null ? frame.ringColor : null,
        ),
        child: circle,
      ),
    );
  }
}
