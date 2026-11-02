import 'package:flutter/material.dart';

import 'avatar.dart';

/// A cosmetic decorative ring drawn AROUND the avatar circle. Shared across all
/// games and rendered by [AvatarBadge]. Frames are earned/cosmetic only (never
/// pay-to-win): most are free-on-unlock, a couple cost modest coins.
///
/// Reuses the existing [AvatarUnlock] / [AvatarUnlockKind] gating from
/// avatar.dart, so NO new unlock logic is needed — [PlayerProfile] evaluates a
/// frame's [unlock] with the same generalized `isUnlocked` / `unlockProgress`
/// it uses for avatars.
class AvatarFrame {
  const AvatarFrame({
    required this.id,
    required this.name,
    required this.ringWidth,
    this.ringColor,
    this.gradient,
    this.cost = 0,
    this.unlock,
  });

  final String id;

  /// Kid-facing name (localized via the `frame.name` catalog domain).
  final String name;

  /// Ring thickness in logical pixels. 0 means no ring (the default 'none').
  final double ringWidth;

  /// Solid ring color. Used when [gradient] is null and [ringWidth] > 0.
  final Color? ringColor;

  /// Optional sweep-gradient colors for a fancier ring (overrides [ringColor]).
  final List<Color>? gradient;

  /// Coin cost in the shop. 0 means free-on-unlock (or free from the start).
  final int cost;

  /// Optional unlock requirement, reusing the avatar gating model. `null` means
  /// always available (the default 'none' frame and any always-free frames).
  final AvatarUnlock? unlock;

  /// Whether this frame draws a visible ring.
  bool get hasRing => ringWidth > 0;
}

/// The shared catalog of avatar frames available in the hub shop.
class AvatarFrames {
  AvatarFrames._();

  /// The default "no ring" frame. Always owned and selectable.
  static const String defaultId = 'none';

  /// The frame granted as the day-7 daily-login finale (see
  /// PlayerProfile.claimDailyLogin). Kept here so the ladder wiring references
  /// a single stable id.
  static const String dailyRewardFrameId = 'gold';

  static const List<AvatarFrame> all = [
    // Default — no ring. Always owned, so every child can go frame-free.
    AvatarFrame(
      id: 'none',
      name: 'None',
      ringWidth: 0,
    ),
    // Always-free starter rings (owned the moment the shop opens via the
    // null-unlock + cost 0 path), so a child always has a few to pick from.
    AvatarFrame(
      id: 'sky',
      name: 'Sky',
      ringWidth: 4,
      ringColor: Color(0xFF4FC3F7),
    ),
    AvatarFrame(
      id: 'leaf',
      name: 'Leaf',
      ringWidth: 4,
      ringColor: Color(0xFF66BB6A),
    ),
    // Cheap coin-buy ring, early reachable.
    AvatarFrame(
      id: 'bronze',
      name: 'Bronze',
      ringWidth: 5,
      ringColor: Color(0xFFCD7F32),
      cost: 30,
    ),
    // Streak-gated silver (free on unlock).
    AvatarFrame(
      id: 'silver',
      name: 'Silver',
      ringWidth: 5,
      ringColor: Color(0xFFB0BEC5),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.dailyStreak,
        threshold: 3,
        label: 'Play 3 days in a row',
      ),
    ),
    // Day-7 login finale frame — also claimable in the shop once a 7-day streak
    // is reached (so it is never permanently gated behind the login timing).
    AvatarFrame(
      id: 'gold',
      name: 'Gold',
      ringWidth: 6,
      gradient: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFFE082)],
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.dailyStreak,
        threshold: 7,
        label: 'Play 7 days in a row',
      ),
    ),
    // Coin-milestone ring.
    AvatarFrame(
      id: 'ocean',
      name: 'Ocean',
      ringWidth: 5,
      gradient: [Color(0xFF26C6DA), Color(0xFF1E88E5), Color(0xFF26C6DA)],
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.lifetimeCoins,
        threshold: 300,
        label: 'Earn 300 coins in total',
      ),
    ),
    // Pet-level ring (fun "stars").
    AvatarFrame(
      id: 'stars',
      name: 'Stars',
      ringWidth: 6,
      gradient: [Color(0xFFBA68C8), Color(0xFF7E57C2), Color(0xFFBA68C8)],
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.petLevel,
        threshold: 10,
        label: 'Grow Buddy to level 10',
      ),
    ),
    // Flower ring gated on owning several avatars (a light collection goal).
    AvatarFrame(
      id: 'flower',
      name: 'Flower',
      ringWidth: 6,
      gradient: [Color(0xFFF06292), Color(0xFFEC407A), Color(0xFFF06292)],
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.ownedAvatars,
        threshold: 4,
        label: 'Own 4 avatars',
      ),
    ),
    // Rainbow trophy ring — gated on a game-mastery achievement.
    AvatarFrame(
      id: 'rainbow',
      name: 'Rainbow',
      ringWidth: 7,
      gradient: [
        Color(0xFFE53935),
        Color(0xFFFFB300),
        Color(0xFF43A047),
        Color(0xFF1E88E5),
        Color(0xFF8E24AA),
        Color(0xFFE53935),
      ],
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'avatar_wardrobe',
        label: 'Own 6 avatars',
      ),
    ),
  ];

  static AvatarFrame byId(String id) =>
      all.firstWhere((f) => f.id == id, orElse: () => all.first);
}
