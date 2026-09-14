import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import '../models/avatar.dart';
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

  static const _kCoins = 'profile_coins';
  static const _kLifetime = 'profile_lifetime_coins';
  static const _kOwned = 'profile_owned_avatars';
  static const _kSelected = 'profile_selected_avatar';
  static const _kAchievements = 'profile_achievements';
  static const _kPlayed = 'profile_played_games';
  static const _kSound = 'profile_sound';

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
    _loaded = true;
    notifyListeners();
  }

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
    await _prefs?.remove(_kCoins);
    await _prefs?.remove(_kLifetime);
    await _prefs?.remove(_kOwned);
    await _prefs?.remove(_kSelected);
    await _prefs?.remove(_kAchievements);
    await _prefs?.remove(_kPlayed);
    await _prefs?.remove(_kSound);
    notifyListeners();
  }
}
