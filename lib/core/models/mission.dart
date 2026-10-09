/// The kinds of progress a mission tracks. Games report events and the
/// PlayerProfile advances any active mission that matches the metric.
enum MissionMetric {
  /// Any question answered correctly (across all games).
  correctAnswers,

  /// Any level/round finished.
  levelsFinished,

  /// Coins earned (cumulative that day).
  coinsEarned,

  /// A level finished with 3 stars.
  threeStarRounds,

  /// A boss/guardian beaten.
  bossesBeaten,
}

/// A single mission definition: a goal with a target amount and a reward.
class MissionDef {
  const MissionDef({
    required this.id,
    required this.title,
    required this.emoji,
    required this.metric,
    required this.target,
    required this.rewardCoins,
  });

  final String id;
  final String title;
  final String emoji;
  final MissionMetric metric;
  final int target;
  final int rewardCoins;
}

/// The pool of daily missions. Three are chosen each day (seeded by the date)
/// so the board rotates. Keep ids stable.
class Missions {
  Missions._();

  static const List<MissionDef> pool = [
    MissionDef(
      id: 'answer_15',
      title: 'Answer 15 questions right',
      emoji: '✅',
      metric: MissionMetric.correctAnswers,
      target: 15,
      rewardCoins: 20,
    ),
    MissionDef(
      id: 'answer_30',
      title: 'Answer 30 questions right',
      emoji: '🎯',
      metric: MissionMetric.correctAnswers,
      target: 30,
      rewardCoins: 40,
    ),
    MissionDef(
      id: 'finish_3',
      title: 'Finish 3 levels',
      emoji: '🏁',
      metric: MissionMetric.levelsFinished,
      target: 3,
      rewardCoins: 25,
    ),
    MissionDef(
      id: 'coins_60',
      title: 'Earn 60 coins',
      emoji: '🪙',
      metric: MissionMetric.coinsEarned,
      target: 60,
      rewardCoins: 20,
    ),
    MissionDef(
      id: 'three_star_2',
      title: 'Get 3 stars twice',
      emoji: '🌟',
      metric: MissionMetric.threeStarRounds,
      target: 2,
      rewardCoins: 35,
    ),
    MissionDef(
      id: 'boss_1',
      title: 'Beat a boss',
      emoji: '⚔️',
      metric: MissionMetric.bossesBeaten,
      target: 1,
      rewardCoins: 30,
    ),
  ];

  static MissionDef byId(String id) =>
      pool.firstWhere((m) => m.id == id, orElse: () => pool.first);

  /// Picks today's three missions deterministically from the date, so the
  /// board is stable across a day and rotates day to day.
  static List<MissionDef> forDay(DateTime day) {
    final seed = day.year * 1000 + day.month * 50 + day.day;
    final order = List<MissionDef>.from(pool);
    // Simple deterministic shuffle using the seed.
    for (var i = order.length - 1; i > 0; i--) {
      final j = (seed * (i + 7)) % (i + 1);
      final tmp = order[i];
      order[i] = order[j];
      order[j] = tmp;
    }
    return order.take(3).toList();
  }
}
