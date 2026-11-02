// Engagement Phase 2 — Avatar Frames. Locks in the PlayerProfile additions:
// the generalized isUnlocked/unlockProgress (regression for avatars), the
// frame ownership/selection/claim/grant APIs, the day-7 login frame grant
// (idempotent), and the new persistence keys + reset().

import 'package:brain_buddies/core/models/avatar.dart';
import 'package:brain_buddies/core/models/avatar_frame.dart';
import 'package:brain_buddies/core/models/daily_reward.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('generalized unlock (avatar regression)', () {
    // The avatar unlock methods now delegate to isUnlocked/unlockProgress.
    // These assertions mirror the avatar-unlock test so the behavior is proven
    // identical after the extract.
    test('isUnlocked/unlockProgress match isAvatarUnlocked across the catalog',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      for (final a in Avatars.all) {
        expect(profile.isUnlocked(a.unlock), profile.isAvatarUnlocked(a),
            reason: '${a.id} unlocked mismatch');
        expect(profile.unlockProgress(a.unlock), profile.avatarUnlockProgress(a),
            reason: '${a.id} progress mismatch');
      }

      // A null unlock is always unlocked with full progress.
      expect(profile.isUnlocked(null), isTrue);
      expect(profile.unlockProgress(null), 1.0);
    });

    test('achievement gate flips once granted (via isUnlocked)', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      final hero = Avatars.byId('nq_hero'); // gated on 'nq_boss'
      expect(profile.isUnlocked(hero.unlock), isFalse);
      await profile.grant('nq_boss');
      expect(profile.isUnlocked(hero.unlock), isTrue);
    });
  });

  group('frame ownership / selection / claim', () {
    test("'none' is owned+selected by default; selecting an unowned frame no-ops",
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.ownsFrame(AvatarFrames.defaultId), isTrue);
      expect(profile.selectedFrameId, AvatarFrames.defaultId);

      // 'gold' is gated (not owned yet) — selecting it does nothing.
      expect(profile.ownsFrame('gold'), isFalse);
      await profile.selectFrame('gold');
      expect(profile.selectedFrameId, AvatarFrames.defaultId);
    });

    test('a free frame claims and equips; owned persists', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      final sky = AvatarFrames.byId('sky'); // always-free (null unlock, cost 0)
      expect(sky.unlock, isNull);
      expect(profile.isFrameUnlocked(sky), isTrue);

      expect(await profile.claimFrame(sky), isTrue);
      expect(profile.ownsFrame('sky'), isTrue);

      await profile.selectFrame('sky');
      expect(profile.selectedFrameId, 'sky');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('profile_owned_frames'), contains('sky'));
      expect(prefs.getString('profile_selected_frame'), 'sky');
    });

    test('a coin-cost frame requires coins at claim time', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      final bronze = AvatarFrames.byId('bronze'); // cost 30, no gate
      expect(bronze.cost, 30);
      expect(await profile.claimFrame(bronze), isFalse,
          reason: 'no coins yet');
      expect(profile.ownsFrame('bronze'), isFalse);

      await profile.addCoins(40);
      final before = profile.coins;
      expect(await profile.claimFrame(bronze), isTrue);
      expect(profile.coins, before - 30);
      expect(profile.ownsFrame('bronze'), isTrue);
    });

    test('a gated frame is locked until the requirement is met', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      final stars = AvatarFrames.byId('stars'); // petLevel >= 10
      expect(profile.isFrameUnlocked(stars), isFalse);
      expect(profile.frameUnlockProgress(stars), lessThan(1.0));
      expect(await profile.claimFrame(stars), isFalse);

      await profile.addPetXp(100000);
      expect(profile.petLevel, greaterThanOrEqualTo(10));
      expect(profile.isFrameUnlocked(stars), isTrue);
      expect(profile.frameUnlockProgress(stars), 1.0);
      expect(await profile.claimFrame(stars), isTrue);
      expect(profile.ownsFrame('stars'), isTrue);
    });

    test('frameUnlockProgress stays within 0..1 for every frame', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      for (final f in AvatarFrames.all) {
        final p = profile.frameUnlockProgress(f);
        expect(p, inInclusiveRange(0.0, 1.0),
            reason: '${f.id} progress out of range: $p');
      }
    });
  });

  group('day-7 login grants the frame (idempotent)', () {
    test('claiming day 7 grants the daily-reward frame', () async {
      SharedPreferences.setMockInitialValues({'profile_login_cycle': 6});
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.todaysLoginReward.kind, DailyRewardKind.special);
      expect(profile.ownsFrame(AvatarFrames.dailyRewardFrameId), isFalse);

      final reward = await profile.claimDailyLogin();
      expect(reward, isNotNull);
      expect(profile.ownsFrame(AvatarFrames.dailyRewardFrameId), isTrue);
    });

    test('granting the frame twice is idempotent and does not error', () async {
      SharedPreferences.setMockInitialValues({
        // Already own the day-7 frame from a previous cycle.
        'profile_login_cycle': 6,
        'profile_owned_frames': [AvatarFrames.dailyRewardFrameId],
      });
      final profile = PlayerProfile();
      await profile.load();

      expect(profile.ownsFrame(AvatarFrames.dailyRewardFrameId), isTrue);
      // A second day-7 claim in a later cycle must not throw / double-grant.
      final reward = await profile.claimDailyLogin();
      expect(reward, isNotNull);
      expect(profile.ownsFrame(AvatarFrames.dailyRewardFrameId), isTrue);

      // grantFrame directly: already owned returns false, ownership unchanged.
      expect(await profile.grantFrame(AvatarFrames.dailyRewardFrameId), isFalse);
    });
  });

  group('persistence + reset', () {
    test('owned frames + selected frame round-trip and survive reload',
        () async {
      SharedPreferences.setMockInitialValues({});
      final profile = PlayerProfile();
      await profile.load();

      await profile.claimFrame(AvatarFrames.byId('sky'));
      await profile.selectFrame('sky');

      final reloaded = PlayerProfile();
      await reloaded.load();
      expect(reloaded.ownsFrame('sky'), isTrue);
      expect(reloaded.selectedFrameId, 'sky');
    });

    test('a selected frame that is no longer owned falls back to none',
        () async {
      SharedPreferences.setMockInitialValues({
        // Selected a frame but it is not in the owned list.
        'profile_selected_frame': 'gold',
        'profile_owned_frames': const <String>[],
      });
      final profile = PlayerProfile();
      await profile.load();
      expect(profile.selectedFrameId, AvatarFrames.defaultId);
    });

    test('reset() clears frame keys and restores defaults', () async {
      SharedPreferences.setMockInitialValues({
        'profile_owned_frames': const ['sky', 'bronze'],
        'profile_selected_frame': 'sky',
      });
      final profile = PlayerProfile();
      await profile.load();
      expect(profile.ownsFrame('sky'), isTrue);

      await profile.reset();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get('profile_owned_frames'), isNull);
      expect(prefs.get('profile_selected_frame'), isNull);
      expect(profile.ownsFrame('sky'), isFalse);
      expect(profile.selectedFrameId, AvatarFrames.defaultId);
    });
  });
}
