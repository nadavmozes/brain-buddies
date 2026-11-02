/// The 7-day escalating daily-login reward ladder.
///
/// Mirrors the const-catalog style of [Missions.pool] / [Avatars.all]: a plain
/// `const` list of [DailyRewardDef] the UI and [PlayerProfile] both read. The
/// child claims the box at their current cycle index once per day; the cycle
/// wraps 0 -> 6 and repeats.
///
/// Economy note: coin payouts stay modest versus shop prices (avatars 50-200)
/// so the shop keeps meaning — days 1-6 pay 5/10/15/20/25/30 coins, and day 7
/// is a bigger finale (50 coins + bonus pet XP).

/// What a reward box pays out.
enum DailyRewardKind {
  /// Pays [DailyRewardDef.amount] coins via PlayerProfile.addCoins.
  coins,

  /// A pet treat: pays [DailyRewardDef.amount] as pet XP via addPetXp.
  petTreat,

  /// The day-7 finale: a larger coin bonus PLUS extra pet XP. Kept as its own
  /// kind so it is cleanly swappable to an avatar-frame reward in a later phase
  /// (P2) — change this case's payout in PlayerProfile.claimDailyLogin without
  /// touching the ladder shape or the 0..6 cycle math.
  special,
}

/// One box in the 7-day login calendar.
class DailyRewardDef {
  const DailyRewardDef({
    required this.dayIndex,
    required this.emoji,
    required this.kind,
    required this.amount,
    required this.petXp,
    required this.labelKey,
  });

  /// Position in the 7-day cycle (0..6).
  final int dayIndex;

  /// Kid-facing emoji shown on the box.
  final String emoji;

  /// What this box pays.
  final DailyRewardKind kind;

  /// Primary amount: coins for [DailyRewardKind.coins]/[special], or pet XP for
  /// [DailyRewardKind.petTreat].
  final int amount;

  /// Extra pet XP paid on top of [amount] (only the day-7 [special] uses this).
  final int petXp;

  /// Localization key suffix used to resolve the box's short label via
  /// AppStrings.dailyRewardLabel(labelKey).
  final String labelKey;
}

/// The 7-day ladder. Keep [dayIndex] values 0..6 and stable.
class DailyRewards {
  DailyRewards._();

  static const List<DailyRewardDef> ladder = [
    DailyRewardDef(
      dayIndex: 0,
      emoji: '🪙',
      kind: DailyRewardKind.coins,
      amount: 5,
      petXp: 0,
      labelKey: 'coins',
    ),
    DailyRewardDef(
      dayIndex: 1,
      emoji: '🪙',
      kind: DailyRewardKind.coins,
      amount: 10,
      petXp: 0,
      labelKey: 'coins',
    ),
    DailyRewardDef(
      dayIndex: 2,
      emoji: '🪙',
      kind: DailyRewardKind.coins,
      amount: 15,
      petXp: 0,
      labelKey: 'coins',
    ),
    DailyRewardDef(
      dayIndex: 3,
      emoji: '🪙',
      kind: DailyRewardKind.coins,
      amount: 20,
      petXp: 0,
      labelKey: 'coins',
    ),
    DailyRewardDef(
      dayIndex: 4,
      emoji: '🪙',
      kind: DailyRewardKind.coins,
      amount: 25,
      petXp: 0,
      labelKey: 'coins',
    ),
    DailyRewardDef(
      dayIndex: 5,
      emoji: '🪙',
      kind: DailyRewardKind.coins,
      amount: 30,
      petXp: 0,
      labelKey: 'coins',
    ),
    // Day 7 finale: bigger coin bonus + extra pet XP. Swappable to a frame
    // reward later (see DailyRewardKind.special).
    DailyRewardDef(
      dayIndex: 6,
      emoji: '🎁',
      kind: DailyRewardKind.special,
      amount: 50,
      petXp: 25,
      labelKey: 'special',
    ),
  ];

  /// The reward box at a cycle index (wraps defensively into 0..6).
  static DailyRewardDef atIndex(int index) {
    final i = ((index % ladder.length) + ladder.length) % ladder.length;
    return ladder[i];
  }

  /// The number of boxes in one cycle (7).
  static int get length => ladder.length;
}
