import '../../../core/models/achievement.dart';
import '../../../core/services/game_progress_store.dart';
import '../../../core/services/player_profile.dart';
import '../models/memory_level.dart';

/// Rewards from finishing a Memory Match level.
class MemoryOutcome {
  MemoryOutcome({
    required this.stars,
    required this.coinsEarned,
    required this.isNewFastest,
    required this.bossBeaten,
    required this.elapsedSeconds,
    required this.perfect,
  });

  final int stars;
  final int coinsEarned;
  final bool isNewFastest;
  final bool bossBeaten;
  final int elapsedSeconds;

  /// True when the board was cleared with no wrong flips.
  final bool perfect;
}

/// Per-level stars + fastest times + unlocks for Memory Match. Coins and
/// achievements go to the shared [PlayerProfile].
class MemoryState extends GameProgressStore {
  int _roundsPlayed = 0;

  static const _kRounds = 'memory_rounds';

  @override
  String get keyPrefix => 'memory';

  @override
  List<String> get orderedLevelIds =>
      MemoryMap.allLevels.map((l) => l.id).toList();

  int get roundsPlayed => _roundsPlayed;

  bool isLevelUnlocked(MemoryLevel level) => isLevelUnlockedById(level.id);

  @override
  Future<void> load() async {
    await super.load();
    _roundsPlayed = prefs!.getInt(_kRounds) ?? 0;
    notifyListeners();
  }

  /// Completes a Memory Match level. Stars are based on efficiency: how few
  /// wrong flips relative to a generous allowance. [wrongFlips] is the number
  /// of non-matching pair reveals.
  Future<MemoryOutcome> completeLevel({
    required PlayerProfile profile,
    required MemoryLevel level,
    required int wrongFlips,
    required int elapsedSeconds,
  }) async {
    final pairs = level.pairs;
    // Allowance scales with the board size. Fewer mistakes → more stars.
    final perfect = wrongFlips == 0;
    final stars = wrongFlips == 0
        ? 3
        : wrongFlips <= pairs
            ? 2
            : 1; // always at least 1 for finishing

    await keepBestStars(level.id, stars);

    final bossBeaten = level.isBoss; // finishing the boss grid counts
    final coinsEarned = pairs * 3 + stars * 5 + (bossBeaten ? 20 : 0);
    await profile.addCoins(coinsEarned);

    _roundsPlayed++;

    final isNewFastest =
        await recordFastestIfBest(level.id, stars, elapsedSeconds);

    await prefs?.setInt(_kRounds, _roundsPlayed);

    final ids = <String>[Achievements.firstGame.id];
    if (perfect) {
      ids.add(Achievements.perfectRound.id);
      ids.add(Achievements.memoryMaster.id);
    }
    if (stars == 3) ids.add(Achievements.threeStar.id);
    if (isNewFastest) ids.add(Achievements.speedster.id);
    await profile.grantAll(ids);

    // Hub-wide systems. Treat matched pairs as "correct answers".
    await profile.onRoundFinished(
      correct: pairs,
      coinsEarned: coinsEarned,
      threeStars: stars == 3,
      bossBeaten: bossBeaten,
    );

    notifyListeners();
    return MemoryOutcome(
      stars: stars,
      coinsEarned: coinsEarned,
      isNewFastest: isNewFastest,
      bossBeaten: bossBeaten,
      elapsedSeconds: elapsedSeconds,
      perfect: perfect,
    );
  }

  @override
  Future<void> reset() async {
    await super.reset();
    _roundsPlayed = 0;
    await prefs?.remove(_kRounds);
    notifyListeners();
  }
}
