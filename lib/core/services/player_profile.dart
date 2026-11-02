import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/widgets.dart';
import '../l10n/app_lang.dart';
import '../models/achievement.dart';
import '../models/avatar.dart';
import '../models/daily_reward.dart';
import '../models/game_catalog.dart';
import '../models/mission.dart';
import '../models/pet.dart';
import 'analytics_service.dart';
import 'sound_bridge.dart';

/// The shared, hub-level player profile: coins, avatar ownership + equipped
/// avatar, achievements, and the sound setting. Created once at the hub and
/// passed into every game so these are consistent everywhere.
class PlayerProfile extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _loaded = false;

  // Optional local-only analytics sink, attached once at the hub. The profile
  // depends only on the [AnalyticsSink] interface, never a concrete class.
  AnalyticsSink? _analytics;

  /// Attaches a local-only analytics sink so opens and round-ends are counted.
  void attachAnalytics(AnalyticsSink sink) {
    _analytics = sink;
  }

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

  // Transient (non-persisted) summary of the pet's change in the most recent
  // round, so result screens can surface a small "Buddy grew" moment. Reset
  // at the start of every onRoundFinished.
  int _lastRoundPetXp = 0;
  bool _lastRoundPetLeveledUp = false;
  int _lastRoundPetNewLevel = 0;
  bool _lastRoundPetStageChanged = false;

  // Daily missions: progress per mission id, claimed set, and the day they
  // belong to (progress resets when the calendar day changes).
  final Map<String, int> _missionProgress = {};
  final Set<String> _missionClaimed = {};
  String _missionDay = '';

  // Daily login reward: the day-key of the last claim and the current position
  // in the 7-day cycle (0..6). A gift is claimable whenever today differs from
  // the last-claim day (claimable on APP OPEN, not round end).
  String _loginLastClaim = '';
  int _loginCycle = 0;

  // "Play all 6 today" bonus: the day-key the set belongs to, the distinct set
  // of game ids opened today, and the day-key the bonus was claimed on (so it
  // pays at most once per day). The set rolls over to empty on a new day.
  String _allSixDay = '';
  final Set<String> _allSixSet = {};
  String _allSixClaimed = '';

  // Comeback gift: PERSISTED as a bool so the "Welcome back! 🎁" card survives
  // an app restart until the child actually claims it (a transient flag would
  // vanish if the app rebuilt before they tapped). Set when recordPlayDay sees
  // a >1-day gap that resets the streak; cleared by claimComebackGift().
  bool _comebackPending = false;

  // Streak freeze tokens (max 1 held). A freeze forgives EXACTLY ONE missed day
  // so a single-day gap keeps the streak instead of resetting to 1. One token
  // is granted when the 7-day login cycle completes (the day-7 claim). This is
  // deliberately un-abusable: at most 1 is held, it only covers a single-day
  // gap (a 2+ day gap still resets), and it is consumed on use.
  int _streakFreezes = 0;

  // UI language (English / Hebrew). Persisted additively under [_kLang]. First
  // launch (key absent) defaults from the platform locale: Hebrew device => he,
  // everything else (incl. the en_US test env) => en.
  AppLang _lang = AppLang.en;

  /// Current persistence schema version. Bump (and add migration logic in
  /// [load]) if the profile key layout ever changes. Read + re-stamped on
  /// load; no migration needed yet.
  static const int schemaVersion = 1;

  static const _kSchemaVersion = 'profile_schema_version';
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
  static const _kLang = 'profile_lang';
  // Engagement Phase 1 keys (additive, default-absent-safe — schemaVersion
  // stays 1). All are cleared in reset().
  static const _kLoginLastClaim = 'profile_login_last_claim';
  static const _kLoginCycle = 'profile_login_cycle';
  static const _kAllSixDay = 'profile_allsix_day';
  static const _kAllSixSet = 'profile_allsix_set';
  static const _kAllSixClaimed = 'profile_allsix_claimed';
  static const _kComebackPending = 'profile_comeback_pending';
  static const _kStreakFreezes = 'profile_streak_freezes';

  bool get isLoaded => _loaded;

  /// The current UI language.
  AppLang get lang => _lang;

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

  // Transient pet-change summary from the most recent round (0 when nothing
  // was fed, so a result screen renders no pet moment).
  int get lastRoundPetXp => _lastRoundPetXp;
  bool get lastRoundPetLeveledUp => _lastRoundPetLeveledUp;
  int get lastRoundPetNewLevel => _lastRoundPetNewLevel;
  bool get lastRoundPetStageChanged => _lastRoundPetStageChanged;

  /// Today's three missions.
  List<MissionDef> get todaysMissions => Missions.forDay(DateTime.now());

  int missionProgress(String id) => _missionProgress[id] ?? 0;
  bool missionComplete(MissionDef m) => missionProgress(m.id) >= m.target;
  bool missionClaimed(String id) => _missionClaimed.contains(id);
  bool get hasClaimableMission =>
      todaysMissions.any((m) => missionComplete(m) && !missionClaimed(m.id));

  // ---- daily login reward ----

  /// The current position in the 7-day login cycle (0..6).
  int get loginCycleIndex => _loginCycle;

  /// The reward box the child would claim right now.
  DailyRewardDef get todaysLoginReward => DailyRewards.atIndex(_loginCycle);

  /// Whether today's login gift is still unclaimed (today != last-claim day).
  bool get canClaimDailyLogin => _loginLastClaim != _todayKey();

  // ---- play-all-6 bonus ----

  /// How many distinct games have been opened today (0..6). Rolls over to 0 on
  /// a new day, computed lazily so a session left open past midnight is fresh.
  int get allSixProgress => (_allSixDay == _todayKey()) ? _allSixSet.length : 0;

  /// The distinct game ids opened today (empty on a new day). Lets the UI light
  /// up individual game icons.
  Set<String> get allSixPlayedToday =>
      (_allSixDay == _todayKey()) ? Set.unmodifiable(_allSixSet) : const {};

  /// Whether the "play all 6 today" bonus is claimable: every game played today
  /// and not yet claimed today.
  bool get canClaimAllSix =>
      allSixProgress >= GameCatalog.all.length &&
      _allSixClaimed != _todayKey();

  // ---- comeback gift / streak freeze ----

  /// Whether a friendly "welcome back" gift is waiting (set after a missed-day
  /// gap reset the streak). Persisted so it survives a restart until claimed.
  bool get comebackGiftPending => _comebackPending;

  /// Streak freeze tokens currently held (0 or 1).
  int get streakFreezes => _streakFreezes;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    // Read (default 1 when absent) and re-stamp the schema version. No
    // migration logic needed yet; this just future-proofs the profile.
    final _ = p.getInt(_kSchemaVersion) ?? schemaVersion;
    await p.setInt(_kSchemaVersion, schemaVersion);
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

    // Language: if the key is absent (new/existing player) auto-detect from the
    // platform locale — Hebrew device => he, everything else => en. The test
    // env reports en_US, so existing English-asserting tests stay on English.
    final storedLang = p.getString(_kLang);
    if (storedLang != null) {
      _lang = AppLang.fromCode(storedLang);
    } else {
      _lang = AppLang.fromLocale(
          WidgetsBinding.instance.platformDispatcher.locale);
    }

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

    // Daily login reward (additive, default-safe).
    _loginLastClaim = p.getString(_kLoginLastClaim) ?? '';
    _loginCycle = p.getInt(_kLoginCycle) ?? 0;

    // Play-all-6 tracker: only keep today's set; a stale day starts empty.
    _allSixDay = p.getString(_kAllSixDay) ?? '';
    _allSixClaimed = p.getString(_kAllSixClaimed) ?? '';
    _allSixSet.clear();
    if (_allSixDay == today) {
      _allSixSet.addAll(p.getStringList(_kAllSixSet) ?? const []);
    } else {
      // New day: reset the tracker.
      _allSixDay = today;
      await p.setString(_kAllSixDay, today);
      await p.remove(_kAllSixSet);
    }

    // Comeback gift + streak freezes (additive, default-safe).
    _comebackPending = p.getBool(_kComebackPending) ?? false;
    _streakFreezes = p.getInt(_kStreakFreezes) ?? 0;

    _loaded = true;
    notifyListeners();
  }

  /// Rolls the mission board over to today if the stored day is stale. This
  /// mirrors load()'s else-branch so a session left open past midnight resets
  /// yesterday's progress before any new mission report is applied.
  Future<void> _rolloverMissionsIfNeeded() async {
    final today = _todayKey();
    if (_missionDay != today) {
      _missionDay = today;
      _missionProgress.clear();
      _missionClaimed.clear();
      await _prefs?.setString(_kMissionDay, today);
      await _prefs?.remove(_kMissionProgress);
      await _prefs?.remove(_kMissionClaimed);
    }
  }

  /// Rolls the "play all 6 today" tracker over to today if its stored day is
  /// stale. Mirrors [_rolloverMissionsIfNeeded] so a session left open past
  /// midnight clears yesterday's set before a new game-open is recorded.
  Future<void> _rolloverAllSixIfNeeded() async {
    final today = _todayKey();
    if (_allSixDay != today) {
      _allSixDay = today;
      _allSixSet.clear();
      await _prefs?.setString(_kAllSixDay, today);
      await _prefs?.remove(_kAllSixSet);
    }
  }

  // ---- date helpers ----
  String _todayKey() => _dayKey(DateTime.now());
  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Switches the UI language and persists it (additive key). Rebuilds the app
  /// via [notifyListeners] so the toggle flips strings + RTL live.
  Future<void> setLang(AppLang value) async {
    if (_lang == value) return;
    _lang = value;
    await _prefs?.setString(_kLang, value.code);
    notifyListeners();
  }

  Future<void> setSoundOn(bool value) async {
    _soundOn = value;
    // The profile and each per-game store all write this one global flag
    // (last writer wins). See the note on [SoundBridge.enabled].
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

  // ---- daily login reward ----

  /// Claims today's login gift (callable on APP OPEN). Pays the reward at the
  /// current cycle index via the existing [addCoins]/[addPetXp] grants, then
  /// advances the cycle (wrapping 0..6) and stamps today as the last-claim day.
  /// Returns the claimed [DailyRewardDef], or null if already claimed today.
  ///
  /// Completing the 7-day cycle (claiming the day-7 [DailyRewardKind.special]
  /// box) also grants one streak-freeze token (capped at 1).
  Future<DailyRewardDef?> claimDailyLogin() async {
    if (!canClaimDailyLogin) return null;
    final reward = todaysLoginReward;

    switch (reward.kind) {
      case DailyRewardKind.coins:
        await addCoins(reward.amount);
        break;
      case DailyRewardKind.petTreat:
        await addPetXp(reward.amount);
        break;
      case DailyRewardKind.special:
        // Day-7 finale: coins + bonus pet XP. Swappable to a frame later.
        await addCoins(reward.amount);
        await addPetXp(reward.petXp);
        // Completing the cycle grants one streak freeze (max 1 held).
        if (_streakFreezes < 1) {
          _streakFreezes = 1;
          await _prefs?.setInt(_kStreakFreezes, _streakFreezes);
        }
        break;
    }

    _loginCycle = (_loginCycle + 1) % DailyRewards.length;
    _loginLastClaim = _todayKey();
    await _prefs?.setInt(_kLoginCycle, _loginCycle);
    await _prefs?.setString(_kLoginLastClaim, _loginLastClaim);
    notifyListeners();
    return reward;
  }

  // ---- play-all-6 bonus ----

  /// Claims the "play all 6 today" bonus once per day. Pays a modest 40 coins
  /// via [addCoins]. Returns the coins granted (0 if not claimable).
  Future<int> claimAllSixBonus() async {
    await _rolloverAllSixIfNeeded();
    if (!canClaimAllSix) return 0;
    const bonus = 40;
    _allSixClaimed = _todayKey();
    await _prefs?.setString(_kAllSixClaimed, _allSixClaimed);
    await addCoins(bonus);
    notifyListeners();
    return bonus;
  }

  // ---- comeback gift ----

  /// Claims the friendly "welcome back" gift once pending. Pays a modest 20
  /// coins via [addCoins] and clears the flag. Returns coins granted (0 if no
  /// gift is pending).
  Future<int> claimComebackGift() async {
    if (!_comebackPending) return 0;
    const gift = 20;
    _comebackPending = false;
    await _prefs?.setBool(_kComebackPending, false);
    await addCoins(gift);
    notifyListeners();
    return gift;
  }

  // ---- daily streak (hub-wide) ----

  /// Records that the child played today, advancing the hub-wide daily streak.
  /// Call this when any game round is completed. Returns the current streak.
  Future<int> recordPlayDay() async {
    final today = _todayKey();
    if (_lastPlayedDay == today) return _dailyStreak; // already counted
    final now = DateTime.now();
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    final twoDaysAgo = _dayKey(now.subtract(const Duration(days: 2)));

    if (_lastPlayedDay == yesterday) {
      // UNCHANGED consecutive-day case: advance exactly as before.
      _dailyStreak = _dailyStreak + 1;
    } else if (_lastPlayedDay == twoDaysAgo &&
        _dailyStreak > 0 &&
        _streakFreezes > 0) {
      // Engagement Phase 1: a SINGLE missed day (last played two days ago) is
      // forgiven by consuming one streak-freeze token. The streak is kept and
      // advanced as if yesterday had been played. Only a one-day gap qualifies
      // (a 2+ day gap falls through to the reset below), and the token is
      // consumed, so this is not abusable. No comeback gift here — the streak
      // was saved, so there is nothing to soften.
      _streakFreezes -= 1;
      await _prefs?.setInt(_kStreakFreezes, _streakFreezes);
      _dailyStreak = _dailyStreak + 1;
    } else {
      // UNCHANGED reset case: a gap (no freeze available / applicable) resets
      // the streak to 1. Engagement Phase 1 ADDS a comeback gift so the reset
      // feels friendly rather than punishing — only when a real streak was
      // actually lost (a prior streak existed and this is a true gap, not a
      // brand-new player's first day).
      final hadStreak = _dailyStreak > 0 && _lastPlayedDay.isNotEmpty;
      _dailyStreak = 1;
      if (hadStreak) {
        _comebackPending = true;
        await _prefs?.setBool(_kComebackPending, true);
      }
    }
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
    // Reset the transient pet-moment summary so a 0-coin round shows nothing.
    _lastRoundPetXp = 0;
    _lastRoundPetLeveledUp = false;
    _lastRoundPetNewLevel = 0;
    _lastRoundPetStageChanged = false;

    await recordPlayDay();
    // Pet grows with roughly the coins earned, so playing anything feeds it.
    final beforeLevel = petLevel;
    final beforeStage = Pet.stageForLevel(beforeLevel);
    await addPetXp(coinsEarned);
    final afterLevel = petLevel;
    _lastRoundPetXp = coinsEarned;
    _lastRoundPetNewLevel = afterLevel;
    _lastRoundPetLeveledUp = afterLevel > beforeLevel;
    _lastRoundPetStageChanged =
        Pet.stageForLevel(afterLevel).name != beforeStage.name;
    // Mission progress.
    await reportMission(MissionMetric.correctAnswers, correct);
    await reportMission(MissionMetric.levelsFinished, 1);
    await reportMission(MissionMetric.coinsEarned, coinsEarned);
    if (threeStars) await reportMission(MissionMetric.threeStarRounds, 1);
    if (bossBeaten) await reportMission(MissionMetric.bossesBeaten, 1);
    // Local-only analytics: aggregate counters + latest snapshots.
    _analytics?.recordRound(
        correct: correct, threeStars: threeStars, bossBeaten: bossBeaten);
    await _analytics?.updateSnapshots(
        streak: dailyStreak, petLevel: petLevel, coins: coins);
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
    await _rolloverMissionsIfNeeded();
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
    await _rolloverMissionsIfNeeded();
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

  /// Whether a gated avatar's unlock requirement is satisfied. Avatars with no
  /// [Avatar.unlock] are always considered unlocked.
  bool isAvatarUnlocked(Avatar a) {
    final u = a.unlock;
    if (u == null) return true;
    switch (u.kind) {
      case AvatarUnlockKind.achievement:
        return hasAchievement(u.achievementId!);
      case AvatarUnlockKind.allAchievements:
        return u.achievementIds!.every(hasAchievement);
      case AvatarUnlockKind.petLevel:
        return petLevel >= u.threshold;
      case AvatarUnlockKind.dailyStreak:
        return dailyStreak >= u.threshold;
      case AvatarUnlockKind.ownedAvatars:
        return ownedAvatarCount >= u.threshold;
      case AvatarUnlockKind.lifetimeCoins:
        return lifetimeCoins >= u.threshold;
    }
  }

  /// Progress (0..1) toward a gated avatar's unlock requirement, for a hint UI.
  /// Avatars with no [Avatar.unlock] return 1.
  double avatarUnlockProgress(Avatar a) {
    final u = a.unlock;
    if (u == null) return 1;
    double ratio(int current, int target) {
      if (target <= 0) return 1;
      return (current / target).clamp(0.0, 1.0);
    }

    switch (u.kind) {
      case AvatarUnlockKind.achievement:
        return hasAchievement(u.achievementId!) ? 1 : 0;
      case AvatarUnlockKind.allAchievements:
        final ids = u.achievementIds!;
        if (ids.isEmpty) return 1;
        final met = ids.where(hasAchievement).length;
        return (met / ids.length).clamp(0.0, 1.0);
      case AvatarUnlockKind.petLevel:
        return ratio(petLevel, u.threshold);
      case AvatarUnlockKind.dailyStreak:
        return ratio(dailyStreak, u.threshold);
      case AvatarUnlockKind.ownedAvatars:
        return ratio(ownedAvatarCount, u.threshold);
      case AvatarUnlockKind.lifetimeCoins:
        return ratio(lifetimeCoins, u.threshold);
    }
  }

  /// Claims a gated avatar once its requirement is met. Returns false if the
  /// avatar is still locked or is premium/coming-soon; true if already owned.
  /// If [Avatar.cost] > 0 the claim deducts coins (an "unlock then buy"
  /// avatar); the same collector/wardrobe grants as [buyAvatar] run on success.
  Future<bool> claimAvatar(Avatar avatar) async {
    if (avatar.premium || avatar.comingSoon) return false;
    if (!isAvatarUnlocked(avatar)) return false;
    if (ownsAvatar(avatar.id)) return true;
    if (avatar.cost > 0) {
      if (_coins < avatar.cost) return false;
      _coins -= avatar.cost;
      await _prefs?.setInt(_kCoins, _coins);
    }
    _ownedAvatars.add(avatar.id);
    await _prefs?.setStringList(_kOwned, _ownedAvatars.toList());
    if (_ownedAvatars.length >= 3) _grant(Achievements.collector.id);
    if (_ownedAvatars.length >= 6) _grant(Achievements.wardrobe.id);
    await _persistAchievements();
    notifyListeners();
    return true;
  }

  /// Buys an avatar with coins. Returns true on success. Premium/coming-soon
  /// avatars can never be bought here.
  Future<bool> buyAvatar(Avatar avatar) async {
    if (avatar.premium || avatar.comingSoon) return false;
    // A gated avatar can't be bought behind its gate.
    if (avatar.unlock != null && !isAvatarUnlocked(avatar)) return false;
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
    // Count every open (including repeats) before the already-played return.
    _analytics?.recordGameOpened(gameId);

    // Engagement Phase 1: track distinct games opened TODAY for the
    // "play all 6" bonus. Rolls over on a new day, then adds this game.
    await _rolloverAllSixIfNeeded();
    if (_allSixSet.add(gameId)) {
      await _prefs?.setStringList(_kAllSixSet, _allSixSet.toList());
      notifyListeners();
    }

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

  // ---- dev / admin helpers ----

  /// Clears the daily-login claim stamp (dev-only) so today's gift can be
  /// claimed again for testing. Does not touch the cycle index.
  Future<void> debugResetDailyLogin() async {
    _loginLastClaim = '';
    await _prefs?.remove(_kLoginLastClaim);
    notifyListeners();
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
    _lang = AppLang.en;
    _loginLastClaim = '';
    _loginCycle = 0;
    _allSixDay = '';
    _allSixSet.clear();
    _allSixClaimed = '';
    _comebackPending = false;
    _streakFreezes = 0;
    await _prefs?.remove(_kSchemaVersion);
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
    await _prefs?.remove(_kLang);
    await _prefs?.remove(_kLoginLastClaim);
    await _prefs?.remove(_kLoginCycle);
    await _prefs?.remove(_kAllSixDay);
    await _prefs?.remove(_kAllSixSet);
    await _prefs?.remove(_kAllSixClaimed);
    await _prefs?.remove(_kComebackPending);
    await _prefs?.remove(_kStreakFreezes);
    notifyListeners();
  }
}
