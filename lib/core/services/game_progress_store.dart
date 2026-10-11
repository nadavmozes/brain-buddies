import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sound_bridge.dart';

/// Shared base for the sibling per-game progress stores (Shape Safari, Word
/// Wizard, Clock Hero, Money Math, Memory Match).
///
/// Holds the common per-level stars + fastest-time maps, the sound toggle, and
/// the level-unlock rule, and persists them with [SharedPreferences] under a
/// per-game [keyPrefix]. The shared_preferences key layout is byte-identical to
/// the previous standalone stores: `<prefix>_sound`, `<prefix>_level_<id>`, and
/// `<prefix>_fastest_<id>`.
///
/// Subclasses supply [keyPrefix] and [orderedLevelIds]. Subclasses with extra
/// persisted fields (best score, rounds played, befriended guardians) override
/// [load]/[reset] to call `super` first and then read/clear their extras, and
/// compose [starsForPercent], [keepBestStars], and [recordFastestIfBest] inside
/// their own `completeLevel`.
abstract class GameProgressStore extends ChangeNotifier {
  @protected
  SharedPreferences? prefs;

  bool _loaded = false;
  bool _soundOn = true;

  /// Current persistence schema version for every per-game store. Bump this
  /// (and add migration logic in [load]) if the key layout ever changes.
  static const int schemaVersion = 1;

  @protected
  final Map<String, int> levelStars = {};

  @protected
  final Map<String, int> levelFastest = {};

  /// Namespace for this game's shared_preferences keys (e.g. `safari`).
  String get keyPrefix;

  /// Level ids in play order; used for unlock gating and persistence loops.
  List<String> get orderedLevelIds;

  bool get isLoaded => _loaded;
  bool get soundOn => _soundOn;

  int stars(String id) => levelStars[id] ?? 0;
  int get totalStars => levelStars.values.fold(0, (s, v) => s + v);
  int fastestSeconds(String id) => levelFastest[id] ?? 0;

  int get overallFastest {
    if (levelFastest.isEmpty) return 0;
    return levelFastest.values.reduce((a, b) => a < b ? a : b);
  }

  bool get hasFastest => levelFastest.isNotEmpty;

  /// A level is unlocked if it's the first stop, or the previous stop in play
  /// order has at least one star.
  bool isLevelUnlockedById(String id) {
    final pos = orderedLevelIds.indexOf(id);
    if (pos <= 0) return true;
    return stars(orderedLevelIds[pos - 1]) > 0;
  }

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    final p = prefs!;
    // Read (default 1 when absent) and re-stamp the schema version. No
    // migration logic needed yet; this just future-proofs the store.
    final _ = p.getInt('${keyPrefix}_schema_version') ?? schemaVersion;
    await p.setInt('${keyPrefix}_schema_version', schemaVersion);
    _soundOn = p.getBool('${keyPrefix}_sound') ?? true;
    SoundBridge.enabled = _soundOn;
    for (final id in orderedLevelIds) {
      final s = p.getInt('${keyPrefix}_level_$id');
      if (s != null) levelStars[id] = s;
      final f = p.getInt('${keyPrefix}_fastest_$id');
      if (f != null) levelFastest[id] = f;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSoundOn(bool value) async {
    _soundOn = value;
    SoundBridge.enabled = value;
    await prefs?.setBool('${keyPrefix}_sound', value);
    notifyListeners();
  }

  Future<void> reset() async {
    levelStars.clear();
    levelFastest.clear();
    _soundOn = true;
    SoundBridge.enabled = true;
    await prefs?.remove('${keyPrefix}_sound');
    await prefs?.remove('${keyPrefix}_schema_version');
    for (final id in orderedLevelIds) {
      await prefs?.remove('${keyPrefix}_level_$id');
      await prefs?.remove('${keyPrefix}_fastest_$id');
    }
    notifyListeners();
  }

  // ---- helpers composed by each subclass's completeLevel ----

  /// Maps a percent score to stars using the shared 90/70/50 thresholds.
  @protected
  int starsForPercent(int percent) => percent >= 90
      ? 3
      : percent >= 70
          ? 2
          : percent >= 50
              ? 1
              : 0;

  /// Keeps the best stars for [id] (only improves), persists on change, and
  /// returns the current stored stars.
  @protected
  Future<int> keepBestStars(String id, int newStars) async {
    if (newStars > stars(id)) {
      levelStars[id] = newStars;
      await prefs?.setInt('${keyPrefix}_level_$id', newStars);
    }
    return stars(id);
  }

  /// Records a new fastest time for [id] when it was a 3-star run with a real
  /// elapsed time that beats the previous record. Returns true on a new record.
  @protected
  Future<bool> recordFastestIfBest(
      String id, int earnedStars, int elapsedSeconds) async {
    if (earnedStars == 3 && elapsedSeconds > 0) {
      final prev = fastestSeconds(id);
      if (prev == 0 || elapsedSeconds < prev) {
        levelFastest[id] = elapsedSeconds;
        await prefs?.setInt('${keyPrefix}_fastest_$id', elapsedSeconds);
        return true;
      }
    }
    return false;
  }
}
