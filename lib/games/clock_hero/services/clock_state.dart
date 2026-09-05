import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/achievement.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/services/sound_bridge.dart';

/// Rewards from finishing a Clock Hero round.
class ClockOutcome {
  ClockOutcome({
    required this.stars,
    required this.coinsEarned,
    required this.isNewBestScore,
    required this.isNewFastest,
    required this.elapsedSeconds,
  });

  final int stars;
  final int coinsEarned;
  final bool isNewBestScore;
  final bool isNewFastest;
  final int elapsedSeconds;
}

/// Persisted state for Clock Hero. Coins & achievements go to the shared
/// [PlayerProfile]; best score and fastest time are local.
class ClockState extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _loaded = false;

  int _bestCorrect = 0;
  int _fastestSeconds = 0;
  int _roundsPlayed = 0;
  bool _soundOn = true;

  static const _kBest = 'clock_best';
  static const _kFastest = 'clock_fastest';
  static const _kRounds = 'clock_rounds';
  static const _kSound = 'clock_sound';

  bool get isLoaded => _loaded;
  int get bestCorrect => _bestCorrect;
  int get fastestSeconds => _fastestSeconds;
  bool get hasFastest => _fastestSeconds > 0;
  int get roundsPlayed => _roundsPlayed;
  bool get soundOn => _soundOn;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    _bestCorrect = p.getInt(_kBest) ?? 0;
    _fastestSeconds = p.getInt(_kFastest) ?? 0;
    _roundsPlayed = p.getInt(_kRounds) ?? 0;
    _soundOn = p.getBool(_kSound) ?? true;
    SoundBridge.enabled = _soundOn;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSoundOn(bool value) async {
    _soundOn = value;
    SoundBridge.enabled = value;
    await _prefs?.setBool(_kSound, value);
    notifyListeners();
  }

  Future<ClockOutcome> completeRound({
    required PlayerProfile profile,
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

    final coinsEarned = correct * 3 + stars * 5;
    await profile.addCoins(coinsEarned);

    _roundsPlayed++;
    final isNewBest = correct > _bestCorrect;
    if (isNewBest) _bestCorrect = correct;

    var isNewFastest = false;
    if (percent >= 70) {
      if (_fastestSeconds == 0 || elapsedSeconds < _fastestSeconds) {
        _fastestSeconds = elapsedSeconds;
        isNewFastest = true;
      }
    }

    await _prefs?.setInt(_kBest, _bestCorrect);
    await _prefs?.setInt(_kFastest, _fastestSeconds);
    await _prefs?.setInt(_kRounds, _roundsPlayed);

    final ids = <String>[Achievements.firstGame.id];
    if (correct == total && total > 0) ids.add(Achievements.perfectRound.id);
    await profile.grantAll(ids);

    notifyListeners();
    return ClockOutcome(
      stars: stars,
      coinsEarned: coinsEarned,
      isNewBestScore: isNewBest,
      isNewFastest: isNewFastest,
      elapsedSeconds: elapsedSeconds,
    );
  }

  Future<void> reset() async {
    _bestCorrect = 0;
    _fastestSeconds = 0;
    _roundsPlayed = 0;
    _soundOn = true;
    SoundBridge.enabled = true;
    await _prefs?.remove(_kBest);
    await _prefs?.remove(_kFastest);
    await _prefs?.remove(_kRounds);
    await _prefs?.remove(_kSound);
    notifyListeners();
  }
}
