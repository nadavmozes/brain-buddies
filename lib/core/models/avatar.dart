import 'package:flutter/material.dart';

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
