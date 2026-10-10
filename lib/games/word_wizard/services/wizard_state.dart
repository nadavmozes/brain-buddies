import '../../../core/models/achievement.dart';
import '../../../core/services/game_progress_store.dart';
import '../../../core/services/player_profile.dart';
import '../models/wizard_level.dart';

/// Rewards from finishing a Word Wizard level.
class WizardOutcome {
  WizardOutcome({
    required this.stars,
    required this.coinsEarned,
    required this.isNewBestScore,
    required this.isNewFastest,
    required this.bossBeaten,
    required this.elapsedSeconds,
  });

  final int stars;
  final int coinsEarned;
  final bool isNewBestScore;
  final bool isNewFastest;
  final bool bossBeaten;
  final int elapsedSeconds;
}

/// Persisted state for Word Wizard: per-level stars, fastest times, chapter
/// unlocks. Coins and achievements go to the shared [PlayerProfile].
class WizardState extends GameProgressStore {
  int _bestCorrect = 0;
  int _roundsPlayed = 0;

  static const _kBest = 'wizard_best';
  static const _kRounds = 'wizard_rounds';

  @override
  String get keyPrefix => 'wizard';

  @override
  List<String> get orderedLevelIds =>
      WizardMap.allLevels.map((l) => l.id).toList();

  int get bestCorrect => _bestCorrect;
  int get roundsPlayed => _roundsPlayed;

  /// A level is unlocked if it's the first stop, or the previous stop in play
  /// order has at least one star.
  bool isLevelUnlocked(WizardLevel level) => isLevelUnlockedById(level.id);

  @override
  Future<void> load() async {
    await super.load();
    final p = prefs!;
    _bestCorrect = p.getInt(_kBest) ?? 0;
    _roundsPlayed = p.getInt(_kRounds) ?? 0;
    notifyListeners();
  }

  Future<WizardOutcome> completeLevel({
    required PlayerProfile profile,
    required WizardLevel level,
    required int correct,
    required int total,
    required int elapsedSeconds,
  }) async {
    final percent = total == 0 ? 0 : ((correct / total) * 100).round();
    final stars = starsForPercent(percent);

    // Keep best stars.
    await keepBestStars(level.id, stars);

    // Boss levels require a strong run to beat.
    final bossBeaten = level.isBoss && percent >= 70;

    // Coins go to the SHARED profile.
    final coinsEarned = correct * 3 + stars * 5 + (bossBeaten ? 20 : 0);
    await profile.addCoins(coinsEarned);

    _roundsPlayed++;
    final isNewBest = correct > _bestCorrect;
    if (isNewBest) _bestCorrect = correct;

    // Fastest only counts on a perfect 3-star run.
    final isNewFastest =
        await recordFastestIfBest(level.id, stars, elapsedSeconds);

    await prefs?.setInt(_kBest, _bestCorrect);
    await prefs?.setInt(_kRounds, _roundsPlayed);

    final ids = <String>[Achievements.firstGame.id];
    if (correct == total && total > 0) {
      ids.add(Achievements.perfectRound.id);
      ids.add(Achievements.spellMaster.id);
    }
    if (stars == 3) ids.add(Achievements.threeStar.id);
    if (isNewFastest) ids.add(Achievements.speedster.id);
    await profile.grantAll(ids);

    await profile.onRoundFinished(
      correct: correct,
      coinsEarned: coinsEarned,
      threeStars: stars == 3,
      bossBeaten: bossBeaten,
    );

    notifyListeners();
    return WizardOutcome(
      stars: stars,
      coinsEarned: coinsEarned,
      isNewBestScore: isNewBest,
      isNewFastest: isNewFastest,
      bossBeaten: bossBeaten,
      elapsedSeconds: elapsedSeconds,
    );
  }

  @override
  Future<void> reset() async {
    await super.reset();
    _bestCorrect = 0;
    _roundsPlayed = 0;
    await prefs?.remove(_kBest);
    await prefs?.remove(_kRounds);
    notifyListeners();
  }
}
