/// Engagement Phase 4 (P5b) — per-game MASTERY tiers, plus the Phase 4 (P6)
/// daily-surprise [ChestReward] value type. Framework-free (no Flutter import)
/// so both are trivially unit-testable in isolation.

/// A per-game mastery tier derived from that game's 3-star coverage. The int
/// [rank] 0..3 is what PlayerProfile caches under `profile_mastery_<gameId>`.
enum MasteryTier {
  /// Not every level is cleared (at least one level has 0 stars).
  none(0),

  /// Every level cleared (>= 1 star each), but < 50% are at 3 stars.
  bronze(1),

  /// Bronze met AND >= 50% of levels are at 3 stars.
  silver(2),

  /// Every level is at 3 stars.
  gold(3);

  const MasteryTier(this.rank);

  /// The 0..3 cache value. Also the localized `masteryTierName(rank)` key.
  final int rank;

  /// The tier for a cached 0..3 rank (defensive clamp into range).
  static MasteryTier fromRank(int rank) {
    switch (rank.clamp(0, 3)) {
      case 1:
        return MasteryTier.bronze;
      case 2:
        return MasteryTier.silver;
      case 3:
        return MasteryTier.gold;
      default:
        return MasteryTier.none;
    }
  }
}

/// Computes the [MasteryTier] from a game's per-level star counts, in play
/// order (each 0..3). DOCUMENTED thresholds:
///
///  - `none`   — the list is empty, or any level has 0 stars (not all cleared).
///  - `bronze` — every level has >= 1 star, but fewer than 50% are at 3 stars.
///  - `silver` — every level cleared AND at least 50% are at exactly 3 stars.
///  - `gold`   — every level is at 3 stars (100%).
///
/// Pure + deterministic so the rule never drifts between the six games.
MasteryTier masteryTierForStars(List<int> starsPerLevel) {
  if (starsPerLevel.isEmpty) return MasteryTier.none;
  // Not every level cleared -> none.
  if (starsPerLevel.any((s) => s < 1)) return MasteryTier.none;
  final total = starsPerLevel.length;
  final threeStarCount = starsPerLevel.where((s) => s >= 3).length;
  if (threeStarCount == total) return MasteryTier.gold;
  // >= 50% at 3 stars -> silver (half-up: 2*count >= total avoids float math).
  if (threeStarCount * 2 >= total) return MasteryTier.silver;
  return MasteryTier.bronze;
}

/// What the daily surprise chest (P6) pays out. FIXED, friendly, never empty —
/// no rarity / gambling framing. One of a small fixed set chosen
/// deterministically by the day-key (see PlayerProfile.openChest).
class ChestReward {
  const ChestReward({
    required this.coins,
    required this.treats,
    required this.confetti,
  });

  /// Coins granted via PlayerProfile.addCoins (modest; well below shop prices).
  final int coins;

  /// Pet treats granted via PlayerProfile.addTreats.
  final int treats;

  /// Whether this prize is celebratory enough to fire confetti.
  final bool confetti;
}
