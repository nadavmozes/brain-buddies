import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LOCAL-ONLY, COPPA-safe analytics.
///
/// This records a handful of aggregate counters (how many times a game was
/// opened, how many rounds were played, etc.) entirely on-device in
/// [SharedPreferences]. There is NO network, NO personally identifiable
/// information, and NO fine-grained timestamps — only running totals and the
/// most recent snapshot values. Everything is stored under the 'analytics_'
/// key prefix so it is easy to inspect or clear.
///
/// [PlayerProfile] talks to this only through the [AnalyticsSink] interface, so
/// the profile never depends on the concrete implementation.
abstract class AnalyticsSink {
  /// A game screen was opened from the hub.
  void recordGameOpened(String gameId);

  /// A gameplay round finished.
  void recordRound({
    required int correct,
    required bool threeStars,
    required bool bossBeaten,
  });

  /// Latest hub-wide snapshot values (overwrite, not accumulate).
  Future<void> updateSnapshots({
    required int streak,
    required int petLevel,
    required int coins,
  });
}

class AnalyticsService extends ChangeNotifier implements AnalyticsSink {
  SharedPreferences? _prefs;
  bool _loaded = false;

  // All keys share the 'analytics_' prefix.
  static const _prefix = 'analytics_';
  static const _kOpensPrefix = '${_prefix}opens_';
  static const _kRoundsTotal = '${_prefix}rounds_total';
  static const _kCorrectTotal = '${_prefix}correct_total';
  static const _kThreeStarTotal = '${_prefix}threestar_total';
  static const _kBossTotal = '${_prefix}boss_total';
  static const _kSnapStreak = '${_prefix}snap_streak';
  static const _kSnapPet = '${_prefix}snap_pet';
  static const _kSnapCoins = '${_prefix}snap_coins';

  bool get isLoaded => _loaded;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _loaded = true;
    notifyListeners();
  }

  int _get(String key) => _prefs?.getInt(key) ?? 0;

  Future<void> _bump(String key, int by) async {
    await _prefs?.setInt(key, _get(key) + by);
  }

  // ---- aggregate getters (for tests / future surfacing) ----

  int opensFor(String gameId) => _get('$_kOpensPrefix$gameId');
  int get roundsTotal => _get(_kRoundsTotal);
  int get correctTotal => _get(_kCorrectTotal);
  int get threeStarTotal => _get(_kThreeStarTotal);
  int get bossTotal => _get(_kBossTotal);
  int get snapshotStreak => _get(_kSnapStreak);
  int get snapshotPetLevel => _get(_kSnapPet);
  int get snapshotCoins => _get(_kSnapCoins);

  // ---- AnalyticsSink ----

  @override
  void recordGameOpened(String gameId) {
    _bump('$_kOpensPrefix$gameId', 1);
    notifyListeners();
  }

  @override
  void recordRound({
    required int correct,
    required bool threeStars,
    required bool bossBeaten,
  }) {
    _bump(_kRoundsTotal, 1);
    if (correct > 0) _bump(_kCorrectTotal, correct);
    if (threeStars) _bump(_kThreeStarTotal, 1);
    if (bossBeaten) _bump(_kBossTotal, 1);
    notifyListeners();
  }

  @override
  Future<void> updateSnapshots({
    required int streak,
    required int petLevel,
    required int coins,
  }) async {
    await _prefs?.setInt(_kSnapStreak, streak);
    await _prefs?.setInt(_kSnapPet, petLevel);
    await _prefs?.setInt(_kSnapCoins, coins);
    notifyListeners();
  }
}
