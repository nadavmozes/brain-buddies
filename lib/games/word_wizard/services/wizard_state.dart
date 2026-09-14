import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/achievement.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/services/sound_bridge.dart';
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
class WizardState extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _loaded = false;

  int _bestCorrect = 0;
  int _roundsPlayed = 0;
  bool _soundOn = true;

  final Map<String, int> _levelStars = {};
  final Map<String, int> _levelFastest = {};

  static const _kBest = 'wizard_best';
  static const _kRounds = 'wizard_rounds';
  static const _kSound = 'wizard_sound';

  bool get isLoaded => _loaded;
  int get bestCorrect => _bestCorrect;
  int get roundsPlayed => _roundsPlayed;
  bool get soundOn => _soundOn;

  int stars(String levelId) => _levelStars[levelId] ?? 0;
  int get totalStars => _levelStars.values.fold(0, (s, v) => s + v);
  int fastestSeconds(String levelId) => _levelFastest[levelId] ?? 0;

  /// The best (fastest) time across all levels, or 0 if none yet.
  int get overallFastest {
    if (_levelFastest.isEmpty) return 0;
    return _levelFastest.values.reduce((a, b) => a < b ? a : b);
  }

  bool get hasFastest => _levelFastest.isNotEmpty;

  /// A level is unlocked if it's the first stop, or the previous stop in play
  /// order has at least one star.
  bool isLevelUnlocked(WizardLevel level) {
    final order = WizardMap.allLevels;
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
    for (final lvl in WizardMap.allLevels) {
      final s = p.getInt('wizard_level_${lvl.id}');
      if (s != null) _levelStars[lvl.id] = s;
      final f = p.getInt('wizard_fastest_${lvl.id}');
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

  Future<WizardOutcome> completeLevel({
    required PlayerProfile profile,
    required WizardLevel level,
    required int correct,
    required int total,
    required int elapsedSeconds,
  }) async {
    final percent = total == 0 ? 0 : ((correct / total) * 100).round();
    final stars = percent >= 90
        ? 3
        : percent >= 70
            ? 2
            : percent >= 50
                ? 1
                : 0;

    // Keep best stars.
    final prevStars = this.stars(level.id);
    if (stars > prevStars) {
      _levelStars[level.id] = stars;
      await _prefs?.setInt('wizard_level_${level.id}', stars);
    }

    // Boss levels require a strong run to beat.
    final bossBeaten = level.isBoss && percent >= 70;

    // Coins go to the SHARED profile.
    final coinsEarned = correct * 3 + stars * 5 + (bossBeaten ? 20 : 0);
    await profile.addCoins(coinsEarned);

    _roundsPlayed++;
    final isNewBest = correct > _bestCorrect;
    if (isNewBest) _bestCorrect = correct;

    // Fastest only counts on a perfect 3-star run.
    var isNewFastest = false;
    if (stars == 3 && elapsedSeconds > 0) {
      final prevFastest = fastestSeconds(level.id);
      if (prevFastest == 0 || elapsedSeconds < prevFastest) {
        _levelFastest[level.id] = elapsedSeconds;
        await _prefs?.setInt('wizard_fastest_${level.id}', elapsedSeconds);
        isNewFastest = true;
      }
    }

    await _prefs?.setInt(_kBest, _bestCorrect);
    await _prefs?.setInt(_kRounds, _roundsPlayed);

    final ids = <String>[Achievements.firstGame.id];
    if (correct == total && total > 0) {
      ids.add(Achievements.perfectRound.id);
      ids.add(Achievements.spellMaster.id);
    }
    if (stars == 3) ids.add(Achievements.threeStar.id);
    if (isNewFastest) ids.add(Achievements.speedster.id);
    await profile.grantAll(ids);

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

  Future<void> reset() async {
    _bestCorrect = 0;
    _roundsPlayed = 0;
    _soundOn = true;
    SoundBridge.enabled = true;
    _levelStars.clear();
    _levelFastest.clear();
    await _prefs?.remove(_kBest);
    await _prefs?.remove(_kRounds);
    await _prefs?.remove(_kSound);
    for (final lvl in WizardMap.allLevels) {
      await _prefs?.remove('wizard_level_${lvl.id}');
      await _prefs?.remove('wizard_fastest_${lvl.id}');
    }
    notifyListeners();
  }
}
