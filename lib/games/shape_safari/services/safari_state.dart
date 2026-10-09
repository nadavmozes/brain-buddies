import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/achievement.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/services/sound_bridge.dart';
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
class SafariState extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _loaded = false;

  int _bestCorrect = 0;
  int _roundsPlayed = 0;
  bool _soundOn = true;

  // Per-level stars: levelId -> stars (0-3).
  final Map<String, int> _levelStars = {};

  // Per-level fastest completion time in seconds: levelId -> seconds.
  final Map<String, int> _levelFastest = {};

  // Ids of guardians the explorer has befriended.
  final Set<String> _befriended = {};

  static const _kBest = 'safari_best';
  static const _kRounds = 'safari_rounds';
  static const _kSound = 'safari_sound';
  static const _kBefriended = 'safari_befriended';

  bool get isLoaded => _loaded;
  int get bestCorrect => _bestCorrect;
  int get roundsPlayed => _roundsPlayed;
  bool get soundOn => _soundOn;

  int stars(String levelId) => _levelStars[levelId] ?? 0;
  int get totalStars => _levelStars.values.fold(0, (s, v) => s + v);
  bool guardianBefriended(String levelId) => _befriended.contains(levelId);

  /// Fastest time (seconds) for a stop, or 0 if none recorded yet.
  int fastestSeconds(String levelId) => _levelFastest[levelId] ?? 0;

  /// A level is unlocked if it's the very first stop, or the previous stop in
  /// play order has at least one star.
  bool isLevelUnlocked(SafariLevel level) {
    final order = SafariMap.allLevels;
    final pos = order.indexWhere((l) => l.id == level.id);
    if (pos <= 0) return true;
    return stars(order[pos - 1].id) > 0;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    _bestCorrect = p.getInt(_kBest) ?? 0;
    _roundsPlayed = p.getInt(_kRounds) ?? 0;
    _soundOn = p.getBool(_kSound) ?? true;
    SoundBridge.enabled = _soundOn;

    _befriended
      ..clear()
      ..addAll(p.getStringList(_kBefriended) ?? const []);
    for (final lvl in SafariMap.allLevels) {
      final s = p.getInt('safari_level_${lvl.id}');
      if (s != null) _levelStars[lvl.id] = s;
      final f = p.getInt('safari_fastest_${lvl.id}');
      if (f != null) _levelFastest[lvl.id] = f;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setSoundOn(bool value) async {
    _soundOn = value;
    SoundBridge.enabled = value;
    await _prefs?.setBool(_kSound, value);
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
    final stars = percent >= 90
        ? 3
        : percent >= 70
            ? 2
            : percent >= 50
                ? 1
                : 0;

    final prev = this.stars(level.id);
    if (stars > prev) {
      _levelStars[level.id] = stars;
      await _prefs?.setInt('safari_level_${level.id}', stars);
    }

    // Fastest time: only count a perfect 3-star run.
    var isNewFastest = false;
    if (stars == 3 && elapsedSeconds > 0) {
      final prevFastest = fastestSeconds(level.id);
      if (prevFastest == 0 || elapsedSeconds < prevFastest) {
        _levelFastest[level.id] = elapsedSeconds;
        await _prefs?.setInt('safari_fastest_${level.id}', elapsedSeconds);
        isNewFastest = true;
      }
    }

    // Coins go to the SHARED profile.
    final coinsEarned =
        correct * 3 + stars * 5 + (guardianBefriended ? 20 : 0);
    await profile.addCoins(coinsEarned);

    _roundsPlayed++;
    final isNewBest = correct > _bestCorrect;
    if (isNewBest) _bestCorrect = correct;

    if (guardianBefriended && !_befriended.contains(level.id)) {
      _befriended.add(level.id);
      await _prefs?.setStringList(_kBefriended, _befriended.toList());
    }

    await _prefs?.setInt(_kRounds, _roundsPlayed);
    await _prefs?.setInt(_kBest, _bestCorrect);

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

  Future<void> reset() async {
    _bestCorrect = 0;
    _roundsPlayed = 0;
    _soundOn = true;
    SoundBridge.enabled = true;
    _levelStars.clear();
    _levelFastest.clear();
    _befriended.clear();
    await _prefs?.remove(_kBest);
    await _prefs?.remove(_kRounds);
    await _prefs?.remove(_kSound);
    await _prefs?.remove(_kBefriended);
    for (final lvl in SafariMap.allLevels) {
      await _prefs?.remove('safari_level_${lvl.id}');
      await _prefs?.remove('safari_fastest_${lvl.id}');
    }
    notifyListeners();
  }
}
