import 'avatar.dart';

/// A playful, cosmetic collectible sticker shown on the trophy shelf. Stickers
/// are PURELY cosmetic keepsakes — DISTINCT from the functional
/// [Achievement] list — earned for reaching friendly milestones.
///
/// Gating reuses the existing [AvatarUnlock] / [AvatarUnlockKind] model from
/// avatar.dart, so NO new unlock engine is needed: [PlayerProfile] evaluates a
/// sticker's [unlock] with the same `isUnlocked` it uses for avatars and
/// frames, and auto-grants owned stickers like achievements.
class Sticker {
  const Sticker({
    required this.id,
    required this.emoji,
    required this.name,
    this.unlock,
  });

  final String id;

  /// Emoji rendered on the shelf tile (no image assets needed).
  final String emoji;

  /// Kid-facing name (localized via the `sticker.name` catalog domain).
  final String name;

  /// Optional unlock requirement, reusing the avatar gating model. `null`
  /// means the sticker is always owned (none here use null, kept for parity).
  final AvatarUnlock? unlock;
}

/// The shared catalog of collectible stickers. Each id is stable once shipped.
/// Every sticker is gated by an [AvatarUnlock] kind the profile already
/// evaluates (achievement | allAchievements | petLevel | dailyStreak |
/// ownedAvatars | lifetimeCoins). These are PLAYFUL cosmetics — deliberately
/// framed as fun keepsakes, not duplicates of the achievement list.
class Stickers {
  Stickers._();

  static const List<Sticker> all = [
    // --- lifetimeCoins milestones (coins pile up as you play anything) ---
    Sticker(
      id: 'star_sticker',
      emoji: '⭐',
      name: 'Shiny Star',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.lifetimeCoins,
        threshold: 100,
        label: 'Earn 100 coins in total',
      ),
    ),
    Sticker(
      id: 'rainbow_sticker',
      emoji: '🌈',
      name: 'Rainbow',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.lifetimeCoins,
        threshold: 400,
        label: 'Earn 400 coins in total',
      ),
    ),
    Sticker(
      id: 'balloon_sticker',
      emoji: '🎈',
      name: 'Party Balloon',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.lifetimeCoins,
        threshold: 700,
        label: 'Earn 700 coins in total',
      ),
    ),
    // --- dailyStreak milestones (play day after day) ---
    Sticker(
      id: 'sun_sticker',
      emoji: '🌞',
      name: 'Sunny Day',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.dailyStreak,
        threshold: 2,
        label: 'Play 2 days in a row',
      ),
    ),
    Sticker(
      id: 'party_sticker',
      emoji: '🎉',
      name: 'Confetti Pop',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.dailyStreak,
        threshold: 5,
        label: 'Play 5 days in a row',
      ),
    ),
    // --- petLevel milestones (your buddy grows) ---
    Sticker(
      id: 'paw_sticker',
      emoji: '🐾',
      name: 'Puppy Paws',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.petLevel,
        threshold: 3,
        label: 'Grow Buddy to level 3',
      ),
    ),
    Sticker(
      id: 'butterfly_sticker',
      emoji: '🦋',
      name: 'Butterfly',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.petLevel,
        threshold: 6,
        label: 'Grow Buddy to level 6',
      ),
    ),
    Sticker(
      id: 'blossom_sticker',
      emoji: '🌸',
      name: 'Cherry Blossom',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.petLevel,
        threshold: 8,
        label: 'Grow Buddy to level 8',
      ),
    ),
    // --- ownedAvatars milestones (collect friends) ---
    Sticker(
      id: 'heart_sticker',
      emoji: '💖',
      name: 'Heart',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.ownedAvatars,
        threshold: 2,
        label: 'Own 2 avatars',
      ),
    ),
    Sticker(
      id: 'crown_sticker',
      emoji: '👑',
      name: 'Tiny Crown',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.ownedAvatars,
        threshold: 5,
        label: 'Own 5 avatars',
      ),
    ),
    // --- achievement gate (a single friendly milestone) ---
    Sticker(
      id: 'rocket_sticker',
      emoji: '🚀',
      name: 'Rocket',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'first_game',
        label: 'Finish your first round',
      ),
    ),
    // --- allAchievements gate (master every game) ---
    Sticker(
      id: 'trophy_sticker',
      emoji: '🏆',
      name: 'Golden Trophy',
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.allAchievements,
        achievementIds: [
          'nq_boss',
          'ss_guardian',
          'ww_master',
          'ch_keeper',
          'mm_master',
          'mem_master',
        ],
        label: 'Master all 6 games',
      ),
    ),
  ];

  static Sticker byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
