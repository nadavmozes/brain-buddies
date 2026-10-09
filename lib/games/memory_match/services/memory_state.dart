import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/achievement.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/services/sound_bridge.dart';
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
class MemoryState extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _loaded = false;

  int _roundsPlayed = 0;
  bool _soundOn = true;

  final Map<String, int> _levelStars = {};
  final Map<String, int> _levelFastest = {};

  static const _kRounds = 'memory_rounds';
  static const _kSound = 'memory_sound';

  bool get isLoaded => _loaded;
  int get roundsPlayed => _roundsPlayed;
  bool get soundOn => _soundOn;

  int stars(String levelId) => _levelStars[levelId] ?? 0;
  int get totalStars => _levelStars.values.fold(0, (s, v) => s + v);
  int fastestSeconds(String levelId) => _levelFastest[levelId] ?? 0;

  int get overallFastest {
    if (_levelFastest.isEmpty) return 0;
    return _levelFastest.values.reduce((a, b) => a < b ? a : b);
  }

  bool get hasFastest => _levelFastest.isNotEmpty;

  bool isLevelUnlocked(MemoryLevel level) {
    final order = MemoryMap.allLevels;
    final pos = order.indexWhere((l) => l.id == level.id);
    if (pos <= 0) return true;
    return stars(order[pos - 1].id) > 0;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    _roundsPlayed = p.getInt(_kRounds) ?? 0;
    _soundOn = p.getBool(_kSound) ?? true;
    SoundBridge.enabled = _soundOn;
    for (final lvl in MemoryMap.allLevels) {
      final s = p.getInt('memory_level_${lvl.id}');
      if (s != null) _levelStars[lvl.id] = s;
      final f = p.getInt('memory_fastest_${lvl.id}');
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
            : wrongFlips <= pairs * 2
                ? 1
                : 1; // always at least 1 for finishing

    final prevStars = this.stars(level.id);
    if (stars > prevStars) {
      _levelStars[level.id] = stars;
      await _prefs?.setInt('memory_level_${level.id}', stars);
    }

    final bossBeaten = level.isBoss; // finishing the boss grid counts
    final coinsEarned = pairs * 3 + stars * 5 + (bossBeaten ? 20 : 0);
    await profile.addCoins(coinsEarned);

    _roundsPlayed++;

    var isNewFastest = false;
    if (stars == 3 && elapsedSeconds > 0) {
      final prevFastest = fastestSeconds(level.id);
      if (prevFastest == 0 || elapsedSeconds < prevFastest) {
        _levelFastest[level.id] = elapsedSeconds;
        await _prefs?.setInt('memory_fastest_${level.id}', elapsedSeconds);
        isNewFastest = true;
      }
    }

    await _prefs?.setInt(_kRounds, _roundsPlayed);

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

  Future<void> reset() async {
    _roundsPlayed = 0;
    _soundOn = true;
    SoundBridge.enabled = true;
    _levelStars.clear();
    _levelFastest.clear();
    await _prefs?.remove(_kRounds);
    await _prefs?.remove(_kSound);
    for (final lvl in MemoryMap.allLevels) {
      await _prefs?.remove('memory_level_${lvl.id}');
      await _prefs?.remove('memory_fastest_${lvl.id}');
    }
    notifyListeners();
  }
}
