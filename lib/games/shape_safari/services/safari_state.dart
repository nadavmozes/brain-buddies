import '../../../core/models/achievement.dart';
import '../../../core/services/game_progress_store.dart';
import '../../../core/services/player_profile.dart';
import '../models/safari_level.dart';

/// Rewards from finishing a Shape Safari level.
class SafariOutcome {
  SafariOutcome({
    required this.stars,
    required this.coinsEarned,
    required this.isNewBest,
    required this.guardianBefriended,
    required this.elapsedSeconds,
    required this.isNewFastest,
  });

  final int stars;
  final int coinsEarned;
  final bool isNewBest;
  final bool guardianBefriended;
  final int elapsedSeconds;
  final bool isNewFastest;
}

/// Persisted state for Shape Safari: coins, per-level stars, trail unlocks,
/// befriended guardians, best score, rounds, and sound.
class SafariState extends GameProgressStore {
  int _bestCorrect = 0;
  int _roundsPlayed = 0;

  // Ids of guardians the explorer has befriended.
  final Set<String> _befriended = {};

  static const _kBest = 'safari_best';
  static const _kRounds = 'safari_rounds';
  static const _kBefriended = 'safari_befriended';

  @override
  String get keyPrefix => 'safari';

  @override
  List<String> get orderedLevelIds =>
      SafariMap.allLevels.map((l) => l.id).toList();

  int get bestCorrect => _bestCorrect;
  int get roundsPlayed => _roundsPlayed;

  bool guardianBefriended(String levelId) => _befriended.contains(levelId);

  /// A level is unlocked if it's the very first stop, or the previous stop in
  /// play order has at least one star.
  bool isLevelUnlocked(SafariLevel level) => isLevelUnlockedById(level.id);

  @override
  Future<void> load() async {
    await super.load();
    final p = prefs!;
    _bestCorrect = p.getInt(_kBest) ?? 0;
    _roundsPlayed = p.getInt(_kRounds) ?? 0;
    _befriended
      ..clear()
      ..addAll(p.getStringList(_kBefriended) ?? const []);
    notifyListeners();
  }

  /// Applies a finished level: keeps best stars, awards coins, tracks best
  /// score, and records a befriended guardian on a guardian stop.
  Future<SafariOutcome> completeLevel({
    required PlayerProfile profile,
    required SafariLevel level,
    required int correct,
    required int total,
    required bool guardianBefriended,
    int elapsedSeconds = 0,
  }) async {
    final percent = total == 0 ? 0 : ((correct / total) * 100).round();
    final stars = starsForPercent(percent);

    await keepBestStars(level.id, stars);

    // Fastest time: only count a perfect 3-star run.
    final isNewFastest =
        await recordFastestIfBest(level.id, stars, elapsedSeconds);

    // Coins go to the SHARED profile.
    final coinsEarned =
        correct * 3 + stars * 5 + (guardianBefriended ? 20 : 0);
    await profile.addCoins(coinsEarned);

    _roundsPlayed++;
    final isNewBest = correct > _bestCorrect;
    if (isNewBest) _bestCorrect = correct;

    if (guardianBefriended && !_befriended.contains(level.id)) {
      _befriended.add(level.id);
      await prefs?.setStringList(_kBefriended, _befriended.toList());
    }

    await prefs?.setInt(_kRounds, _roundsPlayed);
    await prefs?.setInt(_kBest, _bestCorrect);

    // Grant SHARED achievements.
    final ids = <String>[Achievements.firstGame.id];
    if (correct == total && total > 0) ids.add(Achievements.perfectRound.id);
    if (stars == 3) ids.add(Achievements.threeStar.id);
    if (isNewFastest) ids.add(Achievements.speedster.id);
    if (guardianBefriended) ids.add(Achievements.guardianFriend.id);
    // Whole habitat trail cleared?
    final trailLevels = SafariMap.trail(level.habitat).levels;
    if (trailLevels.every((l) => this.stars(l.id) > 0)) {
      ids.add(Achievements.shapeExplorer.id);
    }
    await profile.grantAll(ids);

    await profile.onRoundFinished(
      correct: correct,
      coinsEarned: coinsEarned,
      threeStars: stars == 3,
      bossBeaten: guardianBefriended,
    );

    notifyListeners();
    return SafariOutcome(
      stars: stars,
      coinsEarned: coinsEarned,
      isNewBest: isNewBest,
      guardianBefriended: guardianBefriended,
      elapsedSeconds: elapsedSeconds,
      isNewFastest: isNewFastest,
    );
  }

  @override
  Future<void> reset() async {
    await super.reset();
    _bestCorrect = 0;
    _roundsPlayed = 0;
    _befriended.clear();
    await prefs?.remove(_kBest);
    await prefs?.remove(_kRounds);
    await prefs?.remove(_kBefriended);
    notifyListeners();
  }
}
