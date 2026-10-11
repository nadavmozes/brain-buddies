// Locks in the gated-avatar unlock rules in PlayerProfile:
// isAvatarUnlocked, avatarUnlockProgress, and claimAvatar (free + coin-cost),
// plus the backward-compatible buyAvatar path for ungated avatars.
//
// All state is seeded via SharedPreferences.setMockInitialValues, mirroring the
// style of player_profile_streak_test.dart. Gated avatars reference the real
// catalog entries added for this feature.

import 'package:brain_buddies/core/models/avatar.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Avatar byId(String id) => Avatars.byId(id);

  test('null-unlock avatar is immediately unlocked and buyAvatar still works',
      () async {
    SharedPreferences.setMockInitialValues({'profile_coins': 500});
    final profile = PlayerProfile();
    await profile.load();

    final wizard = byId('wizard'); // ungated, cost 50
    expect(wizard.unlock, isNull);
    expect(profile.isAvatarUnlocked(wizard), isTrue);
    expect(profile.avatarUnlockProgress(wizard), 1.0);

    final ok = await profile.buyAvatar(wizard);
    expect(ok, isTrue);
    expect(profile.ownsAvatar('wizard'), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('profile_owned_avatars'), contains('wizard'));
    expect(prefs.getInt('profile_coins'), 450);
  });

  test('achievement-gated avatar is locked until granted, then claimable',
      () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    final hero = byId('nq_hero'); // gated on 'nq_boss', free
    expect(hero.unlock, isNotNull);
    expect(profile.isAvatarUnlocked(hero), isFalse);
    expect(profile.avatarUnlockProgress(hero), 0.0);
    // Can't buy or claim behind the gate.
    expect(await profile.buyAvatar(hero), isFalse);
    expect(await profile.claimAvatar(hero), isFalse);
    expect(profile.ownsAvatar('nq_hero'), isFalse);

    await profile.grant('nq_boss');
    expect(profile.isAvatarUnlocked(hero), isTrue);
    expect(profile.avatarUnlockProgress(hero), 1.0);

    final claimed = await profile.claimAvatar(hero);
    expect(claimed, isTrue);
    expect(profile.ownsAvatar('nq_hero'), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('profile_owned_avatars'), contains('nq_hero'));
  });

  test('allAchievements-gated avatar unlocks only when ALL six are granted',
      () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    final champ = byId('grand_champion');
    const ids = [
      'nq_boss',
      'ss_guardian',
      'ww_master',
      'ch_keeper',
      'mm_master',
      'mem_master',
    ];
    expect(profile.isAvatarUnlocked(champ), isFalse);
    expect(profile.avatarUnlockProgress(champ), 0.0);

    // Grant five of six: still locked, progress is a sensible partial.
    for (final id in ids.take(5)) {
      await profile.grant(id);
    }
    expect(profile.isAvatarUnlocked(champ), isFalse);
    expect(profile.avatarUnlockProgress(champ), closeTo(5 / 6, 1e-9));

    // Grant the last one: now unlocked and progress is full.
    await profile.grant(ids.last);
    expect(profile.isAvatarUnlocked(champ), isTrue);
    expect(profile.avatarUnlockProgress(champ), 1.0);
    expect(await profile.claimAvatar(champ), isTrue);
    expect(profile.ownsAvatar('grand_champion'), isTrue);
  });

  test('petLevel-gated avatar unlocks at the threshold', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    final blaze = byId('phoenix_pal'); // gated on petLevel >= 10
    expect(profile.isAvatarUnlocked(blaze), isFalse);
    expect(profile.avatarUnlockProgress(blaze), lessThan(1.0));
    expect(profile.avatarUnlockProgress(blaze),
        inInclusiveRange(0.0, 1.0));

    // Feed the pet enough XP to cross level 10.
    await profile.addPetXp(100000);
    expect(profile.petLevel, greaterThanOrEqualTo(10));
    expect(profile.isAvatarUnlocked(blaze), isTrue);
    expect(profile.avatarUnlockProgress(blaze), 1.0);
    expect(await profile.claimAvatar(blaze), isTrue);
    expect(profile.ownsAvatar('phoenix_pal'), isTrue);
  });

  test('a cost>0 gated avatar requires coins at claim time', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    final star = byId('star_master'); // gated on 'avatar_wardrobe', cost 100
    expect(star.cost, 100);

    // Meet the gate but have no coins: claim fails.
    await profile.grant('avatar_wardrobe');
    expect(profile.isAvatarUnlocked(star), isTrue);
    expect(await profile.claimAvatar(star), isFalse);
    expect(profile.ownsAvatar('star_master'), isFalse);

    // Earn enough coins, then claim succeeds and deducts the cost.
    await profile.addCoins(150);
    final before = profile.coins;
    expect(await profile.claimAvatar(star), isTrue);
    expect(profile.ownsAvatar('star_master'), isTrue);
    expect(profile.coins, before - 100);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('profile_owned_avatars'), contains('star_master'));
  });

  test('avatarUnlockProgress stays within 0..1 for threshold gates', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    for (final a in Avatars.all) {
      final p = profile.avatarUnlockProgress(a);
      expect(p, inInclusiveRange(0.0, 1.0),
          reason: '${a.id} progress out of range: $p');
    }
  });
}
