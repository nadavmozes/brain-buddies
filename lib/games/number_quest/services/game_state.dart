import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/achievement.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/services/sound_bridge.dart';
import '../models/difficulty.dart';
import '../models/level.dart';
import '../models/skill.dart';

/// The result of finishing a level, returned so the UI can show rewards.
class LevelOutcome {
  LevelOutcome({
    required this.stars,
    required this.coinsEarned,
    required this.xpEarned,
    required this.leveledUp,
    required this.newLevel,
    required this.newAchievements,
    required this.elapsedSeconds,
    required this.isNewFastest,
  });

  final int stars;
  final int coinsEarned;
  final int xpEarned;
  final bool leveledUp;
  final int newLevel;

  /// Shared achievements newly earned this level (for the celebration).
  final List<Achievement> newAchievements;

  /// How long this level took, and whether it set a new fastest record.
  final int elapsedSeconds;
  final bool isNewFastest;
}

/// Central, persisted game state. Everything (economy, progression,
/// cosmetics, stats, achievements) lives here so screens stay simple.
class GameState extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _loaded = false;

  // Progression (coins & cosmetics now live in the shared PlayerProfile)
  int _xp = 0;

  // Per-level stars: levelId -> stars (0-3)
  final Map<String, int> _levelStars = {};

  // Per-level fastest completion time in seconds: levelId -> seconds.
  final Map<String, int> _levelFastest = {};

  // Daily streak
  int _dailyStreak = 0;
  String _lastPlayedDay = '';

  // Skill accuracy stats
  final Map<Skill, SkillStat> _skills = {
    for (final s in Skill.values) s: SkillStat(),
  };

  // Settings (mirrors the shared profile; kept for the in-game toggle)
  bool _soundOn = true;

  // Aggregate lifetime counters (for achievements)
  int _bestAnswerStreak = 0;
  int _multCorrect = 0;

  // ---- keys ----
  static const _kXp = 'xp';
  static const _kStreak = 'daily_streak';
  static const _kLastDay = 'last_day';
  static const _kSound = 'sound_on';
  static const _kBestStreak = 'best_answer_streak';
  static const _kMultCorrect = 'mult_correct';

  // ---- getters ----
  bool get isLoaded => _loaded;
  int get xp => _xp;
  int get dailyStreak => _dailyStreak;
  bool get soundOn => _soundOn;

  /// Hero level derived from XP. Each level needs a bit more than the last.
  int get level => _levelForXp(_xp);
  int _levelForXp(int xp) {
    var lvl = 1;
    var need = 100;
    var remaining = xp;
    while (remaining >= need) {
      remaining -= need;
      lvl++;
      need += 50; // 100, 150, 200, ...
    }
    return lvl;
  }

  /// XP progress toward the next level, 0..1.
  double get levelProgress {
    var need = 100;
    var remaining = _xp;
    while (remaining >= need) {
      remaining -= need;
      need += 50;
    }
    return remaining / need;
  }

  int stars(String levelId) => _levelStars[levelId] ?? 0;
  int get totalStars =>
      _levelStars.values.fold(0, (sum, v) => sum + v);

  /// Fastest time (seconds) for a level, or 0 if none recorded yet.
  int fastestSeconds(String levelId) => _levelFastest[levelId] ?? 0;

  SkillStat skillStat(Skill s) => _skills[s] ?? SkillStat();

  /// A level is unlocked if it's the first level of the easy world, or the
  /// previous level in play order has at least 1 star.
  bool isLevelUnlocked(GameLevel level) {
    final order = WorldMap.allLevels;
    final pos = order.indexWhere((l) => l.id == level.id);
    if (pos <= 0) return true;
    final prev = order[pos - 1];
    return stars(prev.id) > 0;
  }

  // ---- load / save ----
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    _xp = p.getInt(_kXp) ?? 0;
    _dailyStreak = p.getInt(_kStreak) ?? 0;
    _lastPlayedDay = p.getString(_kLastDay) ?? '';
    _soundOn = p.getBool(_kSound) ?? true;
    SoundBridge.enabled = _soundOn;
    _bestAnswerStreak = p.getInt(_kBestStreak) ?? 0;
    _multCorrect = p.getInt(_kMultCorrect) ?? 0;

    for (final lvl in WorldMap.allLevels) {
      final s = p.getInt('level_${lvl.id}');
      if (s != null) _levelStars[lvl.id] = s;
      final f = p.getInt('fastest_${lvl.id}');
      if (f != null) _levelFastest[lvl.id] = f;
    }
    for (final s in Skill.values) {
      _skills[s] = SkillStat(
        correct: p.getInt('${s.key}_correct') ?? 0,
        attempts: p.getInt('${s.key}_attempts') ?? 0,
      );
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

  // ---- gameplay events ----

  /// Records one answered question for skill tracking.
  void recordAnswer(Skill skill, bool correct) {
    final stat = _skills[skill]!;
    stat.attempts++;
    if (correct) {
      stat.correct++;
      if (skill == Skill.multiplication) _multCorrect++;
    }
    _prefs?.setInt('${skill.key}_correct', stat.correct);
    _prefs?.setInt('${skill.key}_attempts', stat.attempts);
    if (skill == Skill.multiplication) {
      _prefs?.setInt(_kMultCorrect, _multCorrect);
    }
    // No notify here; called many times per round. UI reads at round end.
  }

  /// Marks the best answer-streak seen in a round (for the streak badge).
  void reportAnswerStreak(int streak) {
    if (streak > _bestAnswerStreak) {
      _bestAnswerStreak = streak;
      _prefs?.setInt(_kBestStreak, _bestAnswerStreak);
    }
  }

  /// Applies the outcome of a finished level: stars, coins, XP, streak,
  /// and badge checks. Returns a [LevelOutcome] describing the rewards.
  Future<LevelOutcome> completeLevel({
    required PlayerProfile profile,
    required GameLevel level,
    required int correct,
    required int total,
    required int roundScore,
    required int bestAnswerStreak,
    required bool bossDefeated,
    int elapsedSeconds = 0,
  }) async {
    final percent = total == 0 ? 0 : ((correct / total) * 100).round();
    final earnedStars = percent >= 90
        ? 3
        : percent >= 70
            ? 2
            : percent >= 50
                ? 1
                : 0;

    // Stars: keep the best.
    final prevStars = stars(level.id);
    if (earnedStars > prevStars) {
      _levelStars[level.id] = earnedStars;
      await _prefs?.setInt('level_${level.id}', earnedStars);
    }

    // Fastest time: record only on a decent run (>=70%) so rushing-and-missing
    // can't set a bogus record. Skip for the daily challenge (not on the map).
    // Fastest time: only count a perfect 3-star run (skip the daily challenge,
    // which isn't on the map).
    var isNewFastest = false;
    final onMap = WorldMap.allLevels.any((l) => l.id == level.id);
    if (onMap && earnedStars == 3 && elapsedSeconds > 0) {
      final prevFastest = fastestSeconds(level.id);
      if (prevFastest == 0 || elapsedSeconds < prevFastest) {
        _levelFastest[level.id] = elapsedSeconds;
        await _prefs?.setInt('fastest_${level.id}', elapsedSeconds);
        isNewFastest = true;
      }
    }

    // Coins go to the SHARED profile.
    final coinsEarned =
        correct * 2 + earnedStars * 5 + (bossDefeated ? 25 : 0);
    await profile.addCoins(coinsEarned);

    // XP: based on score (local to Number Quest).
    final beforeLevel = level_();
    final xpEarned = roundScore + correct * 5;
    _xp += xpEarned;
    await _prefs?.setInt(_kXp, _xp);
    final afterLevel = level_();
    final leveledUp = afterLevel > beforeLevel;

    reportAnswerStreak(bestAnswerStreak);
    await _updateDailyStreak();

    // Grant SHARED achievements.
    final ids = <String>[Achievements.firstGame.id];
    if (correct == total && total > 0) ids.add(Achievements.perfectRound.id);
    if (earnedStars == 3) ids.add(Achievements.threeStar.id);
    if (isNewFastest) ids.add(Achievements.speedster.id);
    if (bestAnswerStreak >= 5) ids.add(Achievements.streak5.id);
    if (bossDefeated) ids.add(Achievements.bossFriend.id);
    if (_multCorrect >= 50) ids.add(Achievements.multMaster.id);
    if (afterLevel >= 5) ids.add(Achievements.heroLevel5.id);
    final newAchievements = await profile.grantAll(ids);

    // Hub-wide: streak, pet growth, daily missions.
    await profile.onRoundFinished(
      correct: correct,
      coinsEarned: coinsEarned,
      threeStars: earnedStars == 3,
      bossBeaten: bossDefeated,
    );

    notifyListeners();
    return LevelOutcome(
      stars: earnedStars,
      coinsEarned: coinsEarned,
      xpEarned: xpEarned,
      leveledUp: leveledUp,
      newLevel: afterLevel,
      newAchievements: newAchievements,
      elapsedSeconds: elapsedSeconds,
      isNewFastest: isNewFastest,
    );
  }

  int level_() => _levelForXp(_xp);

  /// Updates the daily streak based on the calendar day.
  Future<void> _updateDailyStreak() async {
    final today = _todayKey();
    if (_lastPlayedDay == today) return; // already counted today
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (_lastPlayedDay == yesterday) {
      _dailyStreak++;
    } else {
      _dailyStreak = 1;
    }
    _lastPlayedDay = today;
    await _prefs?.setInt(_kStreak, _dailyStreak);
    await _prefs?.setString(_kLastDay, _lastPlayedDay);
  }

  String _todayKey() => _dayKey(DateTime.now());
  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---- reset ----
  /// Resets Number Quest's local progress (XP, stars, streak, skills).
  /// Shared coins/avatars/achievements are reset from the PlayerProfile.
  Future<void> reset() async {
    _xp = 0;
    _dailyStreak = 0;
    _lastPlayedDay = '';
    _bestAnswerStreak = 0;
    _multCorrect = 0;
    _levelStars.clear();
    _soundOn = true;
    SoundBridge.enabled = true;
    await _prefs?.remove(_kXp);
    await _prefs?.remove(_kStreak);
    await _prefs?.remove(_kLastDay);
    await _prefs?.remove(_kBestStreak);
    await _prefs?.remove(_kMultCorrect);
    await _prefs?.remove(_kSound);
    _levelFastest.clear();
    for (final lvl in WorldMap.allLevels) {
      await _prefs?.remove('level_${lvl.id}');
      await _prefs?.remove('fastest_${lvl.id}');
    }
    for (final s in Skill.values) {
      _skills[s] = SkillStat();
      await _prefs?.remove('${s.key}_correct');
      await _prefs?.remove('${s.key}_attempts');
    }
    notifyListeners();
  }
}
