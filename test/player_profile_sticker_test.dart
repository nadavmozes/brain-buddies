// Engagement Phase 5 / P8 — Collectible stickers. Locks in the PlayerProfile
// additions: stickers auto-grant when their AvatarUnlock condition is met (at
// the achievement grant points), owned stickers persist across a reload, and
// reset() clears the 'profile_owned_stickers' key + ownership.

import 'package:brain_buddies/core/models/avatar.dart';
import 'package:brain_buddies/core/models/sticker.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sticker catalog', () {
    test('ids are unique and byId round-trips', () {
      final ids = Stickers.all.map((s) => s.id).toSet();
      expect(ids.length, Stickers.all.length);
      for (final s in Stickers.all) {
        expect(Stickers.byId(s.id).id, s.id);
      }
    });
  });

  group('auto-grant at grant points', () {
    test('a lifetime-coin sticker auto-grants when coins cross its threshold',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      // 'star_sticker' is gated on 100 lifetime coins.
      expect(profile.hasSticker('star_sticker'), isFalse);

      // addCoins alone bumps lifetime coins; a finished round then triggers
      // the grant check at the onRoundFinished grant point.
      await profile.addCoins(150);
      expect(profile.hasSticker('star_sticker'), isFalse,
          reason: 'addCoins does not itself run the sticker check');

      await profile.onRoundFinished(
        correct: 5,
        coinsEarned: 0,
        threeStars: false,
        bossBeaten: false,
      );
      expect(profile.hasSticker('star_sticker'), isTrue);
    });

    test('a pet-level sticker auto-grants after a round feeds the pet',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      // 'paw_sticker' is gated on pet level 3.
      expect(profile.hasSticker('paw_sticker'), isFalse);
      await profile.addPetXp(100000); // well past level 3
      expect(profile.petLevel, greaterThanOrEqualTo(3));

      await profile.onRoundFinished(
        correct: 1,
        coinsEarned: 0,
        threeStars: false,
        bossBeaten: false,
      );
      expect(profile.hasSticker('paw_sticker'), isTrue);
    });

    test('an owned-avatars sticker auto-grants at the avatar grant point',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      // 'heart_sticker' is gated on owning 2 avatars (default 'ranger' is #1).
      expect(profile.hasSticker('heart_sticker'), isFalse);
      await profile.addCoins(500);
      await profile.buyAvatar(Avatars.byId('cat')); // cost 70, ungated
      expect(profile.ownedAvatarCount, greaterThanOrEqualTo(2));
      expect(profile.hasSticker('heart_sticker'), isTrue);
    });
  });

  group('persistence + reset', () {
    test('owned stickers survive a reload', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();
      await profile.addCoins(150);
      await profile.onRoundFinished(
        correct: 1,
        coinsEarned: 0,
        threeStars: false,
        bossBeaten: false,
      );
      expect(profile.hasSticker('star_sticker'), isTrue);

      final reloaded = PlayerProfile();
      await reloaded.load();
      expect(reloaded.hasSticker('star_sticker'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('profile_owned_stickers'),
          contains('star_sticker'));
    });

    test('reset() clears the stickers key and ownership', () async {
      SharedPreferences.setMockInitialValues({
        'profile_owned_stickers': const ['star_sticker', 'rainbow_sticker'],
      });
      final profile = PlayerProfile();
      await profile.load();
      expect(profile.hasSticker('star_sticker'), isTrue);

      await profile.reset();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get('profile_owned_stickers'), isNull);
      expect(profile.hasSticker('star_sticker'), isFalse);
      expect(profile.ownedStickers, isEmpty);
    });
  });
}
