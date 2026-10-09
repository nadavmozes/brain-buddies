import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import '../models/avatar.dart';
import '../models/mission.dart';
import '../models/pet.dart';
import 'sound_bridge.dart';

/// The shared, hub-level player profile: coins, avatar ownership + equipped
/// avatar, achievements, and the sound setting. Created once at the hub and
/// passed into every game so these are consistent everywhere.
class PlayerProfile extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _loaded = false;

  int _coins = 0;
  int _lifetimeCoins = 0;
  final Set<String> _ownedAvatars = {Avatars.defaultId};
  String _selectedAvatar = Avatars.defaultId;
  final Set<String> _achievements = {};
  final Set<String> _playedGames = {};
  bool _soundOn = true;

  // Hub-wide daily streak (spans all games).
  int _dailyStreak = 0;
  String _lastPlayedDay = '';

  // Pet companion: grows with XP earned across all games.
  int _petXp = 0;

  // Daily missions: progress per mission id, claimed set, and the day they
  // belong to (progress resets when the calendar day changes).
  final Map<String, int> _missionProgress = {};
  final Set<String> _missionClaimed = {};
  String _missionDay = '';

  static const _kCoins = 'profile_coins';
  static const _kLifetime = 'profile_lifetime_coins';
  static const _kOwned = 'profile_owned_avatars';
  static const _kSelected = 'profile_selected_avatar';
  static const _kAchievements = 'profile_achievements';
  static const _kPlayed = 'profile_played_games';
  static const _kSound = 'profile_sound';
  static const _kStreak = 'profile_daily_streak';
  static const _kLastDay = 'profile_last_day';
  static const _kPetXp = 'profile_pet_xp';
  static const _kMissionDay = 'profile_mission_day';
  static const _kMissionProgress = 'profile_mission_progress';
  static const _kMissionClaimed = 'profile_mission_claimed';

  bool get isLoaded => _loaded;
  int get coins => _coins;
  int get lifetimeCoins => _lifetimeCoins;
  bool get soundOn => _soundOn;

  String get selectedAvatarId => _selectedAvatar;
  Avatar get selectedAvatar => Avatars.byId(_selectedAvatar);
  bool ownsAvatar(String id) => _ownedAvatars.contains(id);
  int get ownedAvatarCount => _ownedAvatars.length;

  bool hasAchievement(String id) => _achievements.contains(id);
  int get achievementCount => _achievements.length;

  int get dailyStreak => _dailyStreak;

  int get petXp => _petXp;
  int get petLevel => Pet.levelForXp(_petXp);
  double get petProgress => Pet.progressForXp(_petXp);
  PetStage get petStage => Pet.stageForLevel(petLevel);

  /// Today's three missions.
  List<MissionDef> get todaysMissions => Missions.forDay(DateTime.now());

  int missionProgress(String id) => _missionProgress[id] ?? 0;
  bool missionComplete(MissionDef m) => missionProgress(m.id) >= m.target;
  bool missionClaimed(String id) => _missionClaimed.contains(id);
  bool get hasClaimableMission =>
      todaysMissions.any((m) => missionComplete(m) && !missionClaimed(m.id));

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    _coins = p.getInt(_kCoins) ?? 0;
    _lifetimeCoins = p.getInt(_kLifetime) ?? 0;
    _selectedAvatar = p.getString(_kSelected) ?? Avatars.defaultId;
    _soundOn = p.getBool(_kSound) ?? true;
    SoundBridge.enabled = _soundOn;
    _ownedAvatars
      ..clear()
      ..addAll(p.getStringList(_kOwned) ?? const [Avatars.defaultId]);
    _achievements
      ..clear()
      ..addAll(p.getStringList(_kAchievements) ?? const []);
    _playedGames
      ..clear()
      ..addAll(p.getStringList(_kPlayed) ?? const []);

    _dailyStreak = p.getInt(_kStreak) ?? 0;
    _lastPlayedDay = p.getString(_kLastDay) ?? '';
    _petXp = p.getInt(_kPetXp) ?? 0;

    // Load missions, resetting progress if the stored day is not today.
    _missionDay = p.getString(_kMissionDay) ?? '';
    final today = _todayKey();
    if (_missionDay == today) {
      for (final entry in (p.getStringList(_kMissionProgress) ?? const [])) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          _missionProgress[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
      _missionClaimed
        ..clear()
        ..addAll(p.getStringList(_kMissionClaimed) ?? const []);
    } else {
      // New day: clear out any stale mission state.
      _missionDay = today;
      _missionProgress.clear();
      _missionClaimed.clear();
      await p.setString(_kMissionDay, today);
      await p.remove(_kMissionProgress);
      await p.remove(_kMissionClaimed);
    }

    _loaded = true;
    notifyListeners();
  }

  // ---- date helpers ----
  String _todayKey() => _dayKey(DateTime.now());
  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> setSoundOn(bool value) async {
    _soundOn = value;
    SoundBridge.enabled = value;
    await _prefs?.setBool(_kSound, value);
    notifyListeners();
  }

  // ---- coins ----

  /// Adds coins to the shared balance (also tracks lifetime for achievements).
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    _lifetimeCoins += amount;
    await _prefs?.setInt(_kCoins, _coins);
    await _prefs?.setInt(_kLifetime, _lifetimeCoins);
    // Coin milestone achievements.
    if (_lifetimeCoins >= 200) _grant(Achievements.coin200.id);
    if (_lifetimeCoins >= 500) _grant(Achievements.coin500.id);
    if (_lifetimeCoins >= 1000) _grant(Achievements.coin1000.id);
    await _persistAchievements();
    notifyListeners();
  }

  // ---- daily streak (hub-wide) ----

  /// Records that the child played today, advancing the hub-wide daily streak.
  /// Call this when any game round is completed. Returns the current streak.
  Future<int> recordPlayDay() async {
    final today = _todayKey();
    if (_lastPlayedDay == today) return _dailyStreak; // already counted
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    _dailyStreak = (_lastPlayedDay == yesterday) ? _dailyStreak + 1 : 1;
    _lastPlayedDay = today;
    await _prefs?.setInt(_kStreak, _dailyStreak);
    await _prefs?.setString(_kLastDay, _lastPlayedDay);
    // Streak achievements.
    if (_dailyStreak >= 3) _grant(Achievements.streak3days.id);
    if (_dailyStreak >= 7) _grant(Achievements.streak7days.id);
    await _persistAchievements();
    notifyListeners();
    return _dailyStreak;
  }

  /// A single hub-wide hook games call when a round/level finishes. It bundles
  /// the daily streak, pet growth, and mission progress so each game only needs
  /// one call. [correct] is questions right this round, [coinsEarned] the coins
  /// awarded, [threeStars]/[bossBeaten] flag special outcomes.
  Future<void> onRoundFinished({
    required int correct,
    required int coinsEarned,
    required bool threeStars,
    required bool bossBeaten,
  }) async {
    await recordPlayDay();
    // Pet grows with roughly the coins earned, so playing anything feeds it.
    await addPetXp(coinsEarned);
    // Mission progress.
    await reportMission(MissionMetric.correctAnswers, correct);
    await reportMission(MissionMetric.levelsFinished, 1);
    await reportMission(MissionMetric.coinsEarned, coinsEarned);
    if (threeStars) await reportMission(MissionMetric.threeStarRounds, 1);
    if (bossBeaten) await reportMission(MissionMetric.bossesBeaten, 1);
  }

  // ---- pet companion ----

  /// Adds XP to the pet (earned alongside coins). Grants pet-level awards.
  Future<void> addPetXp(int amount) async {
    if (amount <= 0) return;
    final before = petLevel;
    _petXp += amount;
    await _prefs?.setInt(_kPetXp, _petXp);
    final after = petLevel;
    if (after > before) {
      if (after >= 5) _grant(Achievements.petLevel5.id);
      if (after >= 10) _grant(Achievements.petLevel10.id);
      await _persistAchievements();
    }
    notifyListeners();
  }

  // ---- missions ----

  /// Advances any of today's missions matching [metric] by [amount].
  Future<void> reportMission(MissionMetric metric, int amount) async {
    if (amount <= 0) return;
    var changed = false;
    for (final m in todaysMissions) {
      if (m.metric != metric) continue;
      final current = _missionProgress[m.id] ?? 0;
      if (current >= m.target) continue;
      _missionProgress[m.id] = (current + amount).clamp(0, m.target);
      changed = true;
    }
    if (changed) {
      await _persistMissions();
      notifyListeners();
    }
  }

  /// Claims a completed mission's coin reward. Returns coins granted (0 if not
  /// claimable).
  Future<int> claimMission(MissionDef m) async {
    if (!missionComplete(m) || missionClaimed(m.id)) return 0;
    _missionClaimed.add(m.id);
    await _persistMissions();
    await addCoins(m.rewardCoins);
    // Grant the "finish all daily missions" award if the board is done.
    if (todaysMissions.every((d) => _missionClaimed.contains(d.id))) {
      if (_grant(Achievements.missionsDone.id)) await _persistAchievements();
    }
    notifyListeners();
    return m.rewardCoins;
  }

  Future<void> _persistMissions() async {
    await _prefs?.setString(_kMissionDay, _missionDay);
    await _prefs?.setStringList(_kMissionProgress,
        _missionProgress.entries.map((e) => '${e.key}:${e.value}').toList());
    await _prefs?.setStringList(_kMissionClaimed, _missionClaimed.toList());
  }

  // ---- avatars / shop ----

  /// Buys an avatar with coins. Returns true on success. Premium/coming-soon
  /// avatars can never be bought here.
  Future<bool> buyAvatar(Avatar avatar) async {
    if (avatar.premium || avatar.comingSoon) return false;
    if (ownsAvatar(avatar.id)) return true;
    if (_coins < avatar.cost) return false;
    _coins -= avatar.cost;
    _ownedAvatars.add(avatar.id);
    await _prefs?.setInt(_kCoins, _coins);
    await _prefs?.setStringList(_kOwned, _ownedAvatars.toList());
    if (_ownedAvatars.length >= 3) _grant(Achievements.collector.id);
    if (_ownedAvatars.length >= 6) _grant(Achievements.wardrobe.id);
    await _persistAchievements();
    notifyListeners();
    return true;
  }

  // ---- play tracking (for the "played every game" achievement) ----

  /// Records that a game was opened; grants the Explorer award once all games
  /// have been played. [totalGames] is the number of games in the hub.
  Future<void> recordGamePlayed(String gameId, int totalGames) async {
    if (_playedGames.contains(gameId)) return;
    _playedGames.add(gameId);
    await _prefs?.setStringList(_kPlayed, _playedGames.toList());
    if (_playedGames.length >= totalGames) {
      if (_grant(Achievements.explorer.id)) await _persistAchievements();
    }
    notifyListeners();
  }

  Future<void> selectAvatar(String id) async {
    if (!ownsAvatar(id)) return;
    _selectedAvatar = id;
    await _prefs?.setString(_kSelected, id);
    notifyListeners();
  }

  // ---- achievements ----

  /// Grants one or more achievements by id; returns the newly-earned ones so
  /// the caller can celebrate them.
  Future<List<Achievement>> grantAll(Iterable<String> ids) async {
    final newly = <Achievement>[];
    for (final id in ids) {
      if (_grant(id)) newly.add(Achievements.byId(id));
    }
    if (newly.isNotEmpty) {
      await _persistAchievements();
      notifyListeners();
    }
    return newly;
  }

  /// Grants a single achievement by id; returns true if newly earned.
  Future<bool> grant(String id) async {
    final added = _grant(id);
    if (added) {
      await _persistAchievements();
      notifyListeners();
    }
    return added;
  }

  bool _grant(String id) {
    if (_achievements.contains(id)) return false;
    _achievements.add(id);
    return true;
  }

  Future<void> _persistAchievements() async {
    await _prefs?.setStringList(_kAchievements, _achievements.toList());
  }

  // ---- reset ----

  Future<void> reset() async {
    _coins = 0;
    _lifetimeCoins = 0;
    _ownedAvatars
      ..clear()
      ..add(Avatars.defaultId);
    _selectedAvatar = Avatars.defaultId;
    _achievements.clear();
    _playedGames.clear();
    _soundOn = true;
    SoundBridge.enabled = true;
    _dailyStreak = 0;
    _lastPlayedDay = '';
    _petXp = 0;
    _missionProgress.clear();
    _missionClaimed.clear();
    _missionDay = '';
    await _prefs?.remove(_kCoins);
    await _prefs?.remove(_kLifetime);
    await _prefs?.remove(_kOwned);
    await _prefs?.remove(_kSelected);
    await _prefs?.remove(_kAchievements);
    await _prefs?.remove(_kPlayed);
    await _prefs?.remove(_kSound);
    await _prefs?.remove(_kStreak);
    await _prefs?.remove(_kLastDay);
    await _prefs?.remove(_kPetXp);
    await _prefs?.remove(_kMissionDay);
    await _prefs?.remove(_kMissionProgress);
    await _prefs?.remove(_kMissionClaimed);
    notifyListeners();
  }
}
