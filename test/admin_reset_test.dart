// Verifies the admin "reset everything" wipe clears representative state.
//
// _resetEverything is private to the hub state and is just
// `profile.reset()` + each game store `load()`+`reset()`. This test exercises
// that exact store-level path (the non-reload branch): seed SharedPreferences
// with dirty state, load the stores, reset them, and assert everything is back
// to defaults — in the stores' values AND the underlying prefs keys.

import 'package:brain_buddies/core/models/avatar.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/games/number_quest/models/level.dart';
import 'package:brain_buddies/games/number_quest/services/game_state.dart';
import 'package:brain_buddies/games/shape_safari/models/safari_level.dart';
import 'package:brain_buddies/games/shape_safari/services/safari_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resetEverything clears profile + game stores back to defaults',
      () async {
    final nqFirst = WorldMap.allLevels.first.id;
    final safariFirst = SafariMap.allLevels.first.id;

    SharedPreferences.setMockInitialValues({
      // Dirty shared profile.
      'profile_coins': 999,
      'profile_lifetime_coins': 999,
      'profile_owned_avatars': <String>[Avatars.defaultId, 'wizard'],
      'profile_selected_avatar': 'wizard',
      'profile_achievements': <String>['first_game'],
      'profile_pet_xp': 5000,
      'profile_daily_streak': 7,
      // Dirty per-game stores.
      'nq_level_$nqFirst': 3,
      'nq_fastest_$nqFirst': 12,
      'safari_level_$safariFirst': 2,
    });

    // Seed sanity: load and confirm the dirty state is actually read.
    final profile = PlayerProfile();
    await profile.load();
    expect(profile.coins, 999);
    expect(profile.ownedAvatarCount, 2);
    expect(profile.selectedAvatarId, 'wizard');

    final nq = GameState();
    await nq.load();
    expect(nq.stars(nqFirst), 3);

    final safari = SafariState();
    await safari.load();
    expect(safari.stars(safariFirst), 2);

    // Run the reset path (same calls _resetEverything makes).
    await profile.reset();
    await nq.reset();
    await safari.reset();

    // Profile back to defaults.
    expect(profile.coins, 0);
    expect(profile.lifetimeCoins, 0);
    expect(profile.ownedAvatarCount, 1);
    expect(profile.ownsAvatar(Avatars.defaultId), isTrue);
    expect(profile.selectedAvatarId, Avatars.defaultId);
    expect(profile.achievementCount, 0);
    expect(profile.petXp, 0);
    expect(profile.dailyStreak, 0);

    // Game stores back to defaults.
    expect(nq.stars(nqFirst), 0);
    expect(nq.fastestSeconds(nqFirst), 0);
    expect(safari.stars(safariFirst), 0);

    // Underlying prefs keys were removed, not just the in-memory maps.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('nq_level_$nqFirst'), isFalse);
    expect(prefs.containsKey('nq_fastest_$nqFirst'), isFalse);
    expect(prefs.containsKey('safari_level_$safariFirst'), isFalse);
    expect(prefs.containsKey('profile_coins'), isFalse);
    expect(prefs.containsKey('profile_owned_avatars'), isFalse);
  });
}
