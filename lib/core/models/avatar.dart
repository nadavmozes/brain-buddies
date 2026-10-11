import 'package:flutter/material.dart';

/// How a gated avatar is unlocked (beyond, or instead of, spending coins).
enum AvatarUnlockKind {
  /// Requires a single achievement to be earned ([AvatarUnlock.achievementId]).
  achievement,

  /// Requires ALL of [AvatarUnlock.achievementIds] to be earned.
  allAchievements,

  /// Requires the pet to reach [AvatarUnlock.threshold] level.
  petLevel,

  /// Requires a daily streak of at least [AvatarUnlock.threshold] days.
  dailyStreak,

  /// Requires owning at least [AvatarUnlock.threshold] avatars.
  ownedAvatars,

  /// Requires at least [AvatarUnlock.threshold] lifetime coins earned.
  lifetimeCoins,
}

/// Describes what a player must achieve to unlock an avatar. Kept `const`-
/// constructible so the whole avatar catalog stays a `const` list.
class AvatarUnlock {
  const AvatarUnlock({
    required this.kind,
    this.achievementId,
    this.achievementIds,
    this.threshold = 0,
    required this.label,
  });

  final AvatarUnlockKind kind;

  /// For [AvatarUnlockKind.achievement].
  final String? achievementId;

  /// For [AvatarUnlockKind.allAchievements].
  final List<String>? achievementIds;

  /// For threshold kinds (petLevel / dailyStreak / ownedAvatars / lifetimeCoins).
  final int threshold;

  /// Kid-facing requirement text, e.g. "Grow Buddy to level 10".
  final String label;
}

/// A cosmetic avatar the player can own and equip. Shared across all games.
class Avatar {
  const Avatar({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.cost = 0,
    this.premium = false,
    this.comingSoon = false,
    this.priceLabel,
    this.unlock,
  });

  final String id;
  final String name;

  /// Emoji used to render the avatar (no image assets needed).
  final String emoji;
  final Color color;

  /// Coin cost in the shop. 0 means owned from the start (free).
  final int cost;

  /// A premium avatar bought with real money (not coins).
  final bool premium;

  /// Disabled / not yet purchasable — shown grayed out with a "Coming Soon".
  final bool comingSoon;

  /// Real-money price label for premium avatars, e.g. "$1.99".
  final String? priceLabel;

  /// Optional unlock requirement. `null` means the avatar behaves exactly as
  /// before (free if [cost] is 0, else coin-buy; premium handled separately).
  final AvatarUnlock? unlock;

  bool get isFree => !premium && cost == 0;
}

/// The shared catalog of avatars available in the hub shop.
class Avatars {
  Avatars._();

  static const String defaultId = 'ranger';

  static const List<Avatar> all = [
    // Free starter — a friendly, general character (not a superhero).
    Avatar(
      id: 'ranger',
      name: 'Buddy',
      emoji: '🙂',
      color: Color(0xFF6C63FF),
      cost: 0,
    ),
    // Coin-buyable.
    Avatar(id: 'wizard', name: 'Wizard', emoji: '🧙', color: Color(0xFF7E57C2), cost: 50),
    Avatar(id: 'robot', name: 'Robo', emoji: '🤖', color: Color(0xFF26A69A), cost: 80),
    Avatar(id: 'ninja', name: 'Ninja', emoji: '🥷', color: Color(0xFF455A64), cost: 120),
    Avatar(id: 'unicorn', name: 'Sparkle', emoji: '🦄', color: Color(0xFFEC407A), cost: 150),
    Avatar(id: 'dragon', name: 'Draco', emoji: '🐲', color: Color(0xFF43A047), cost: 200),
    // New coin-buyable avatars.
    Avatar(id: 'astronaut', name: 'Astro', emoji: '🧑‍🚀', color: Color(0xFF1E88E5), cost: 180),
    Avatar(id: 'fox', name: 'Rusty', emoji: '🦊', color: Color(0xFFFB8C00), cost: 110),
    Avatar(id: 'panda', name: 'Bamboo', emoji: '🐼', color: Color(0xFF546E7A), cost: 140),
    Avatar(id: 'owl', name: 'Hooty', emoji: '🦉', color: Color(0xFF8D6E63), cost: 160),
    Avatar(id: 'frog', name: 'Hopper', emoji: '🐸', color: Color(0xFF7CB342), cost: 90),
    // More coin-buyable animals to fill out the shop grid.
    Avatar(id: 'cat', name: 'Whiskers', emoji: '🐱', color: Color(0xFFFF7043), cost: 70),
    Avatar(id: 'penguin', name: 'Waddles', emoji: '🐧', color: Color(0xFF37474F), cost: 100),
    Avatar(id: 'monkey', name: 'Coco', emoji: '🐵', color: Color(0xFF8D6E63), cost: 130),
    // Gated avatars — unlocked by playing. Free (cost 0) unless a cost is noted.
    Avatar(
      id: 'superhero',
      name: 'Captain Brainy',
      emoji: '🦸',
      color: Color(0xFFD32F2F),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'hub_explorer',
        label: 'Play every game once',
      ),
    ),
    Avatar(
      id: 'phoenix_pal',
      name: 'Blaze',
      emoji: '🔥',
      color: Color(0xFFF4511E),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.petLevel,
        threshold: 10,
        label: 'Grow Buddy to level 10',
      ),
    ),
    Avatar(
      id: 'crown',
      name: 'Royalty',
      emoji: '👑',
      color: Color(0xFFFFB300),
      cost: 50,
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.dailyStreak,
        threshold: 7,
        label: 'Play 7 days in a row',
      ),
    ),
    Avatar(
      id: 'star_master',
      name: 'Supernova',
      emoji: '🌟',
      color: Color(0xFF7E57C2),
      cost: 100,
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'avatar_wardrobe',
        label: 'Own 6 avatars',
      ),
    ),
    // Per-game mastery heroes — each gated on that game's existing achievement.
    Avatar(
      id: 'nq_hero',
      name: 'Sir Starlot',
      emoji: '🛡️',
      color: Color(0xFF5C6BC0),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'nq_boss',
        label: 'Beat the Number Quest boss',
      ),
    ),
    Avatar(
      id: 'ss_hero',
      name: 'Trailblazer',
      emoji: '🧭',
      color: Color(0xFF43A047),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'ss_guardian',
        label: 'Befriend a Shape Safari guardian',
      ),
    ),
    Avatar(
      id: 'ww_hero',
      name: 'Spellbinder',
      emoji: '📜',
      color: Color(0xFF7E57C2),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'ww_master',
        label: 'Perfect round in Word Wizard',
      ),
    ),
    Avatar(
      id: 'ch_hero',
      name: 'Timekeeper',
      emoji: '⏰',
      color: Color(0xFFFF9800),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'ch_keeper',
        label: 'Perfect round in Clock Hero',
      ),
    ),
    Avatar(
      id: 'mm_hero',
      name: 'Coin Captain',
      emoji: '💵',
      color: Color(0xFF2E7D32),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'mm_master',
        label: 'Perfect round in Money Math',
      ),
    ),
    Avatar(
      id: 'mem_hero',
      name: 'Mind Master',
      emoji: '🧠',
      color: Color(0xFFAB47BC),
      unlock: AvatarUnlock(
        kind: AvatarUnlockKind.achievement,
        achievementId: 'mem_master',
        label: 'Perfect round in Memory Match',
      ),
    ),
    // All-games trophy — gated on all six per-game achievements at once.
    Avatar(
      id: 'grand_champion',
      name: 'Grand Champion',
      emoji: '🏅',
      color: Color(0xFFFFD700),
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
    // Premium (real money) — a distinct, trophy-worthy avatar. Coming soon.
    Avatar(
      id: 'golden_hero',
      name: 'Champion',
      emoji: '🏆',
      color: Color(0xFFFFC107),
      premium: true,
      comingSoon: true,
      priceLabel: '\$1.99',
    ),
  ];

  static Avatar byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
