// Engagement Phase 5 — P7 season-gated frames. Verifies that a seasonal frame
// is claimable ONLY in its season (the season check is AND-ed into
// PlayerProfile.isFrameUnlocked) while a non-seasonal frame is unaffected.
//
// The gate reads DateTime.now(), so these assertions are framed around the
// CURRENT month's season to stay deterministic on any run.

import 'package:brain_buddies/core/models/avatar_frame.dart';
import 'package:brain_buddies/core/models/season.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The season-gated frames shipped by FEAT-001.
  final seasonalFrames =
      AvatarFrames.all.where((f) => f.season != null).toList();

  test('two season-gated frames exist (frost/winter, blossom/spring)', () {
    expect(seasonalFrames.map((f) => f.id).toSet(), {'frost', 'blossom'});
    expect(AvatarFrames.byId('frost').season, 'winter');
    expect(AvatarFrames.byId('blossom').season, 'spring');
  });

  test('a seasonal frame unlocks only in its season', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();
    // Enough coins so the cost never masks the season gate.
    await profile.addCoins(1000);

    final todaysSeason = Season.forDate(DateTime.now()).key;

    for (final f in seasonalFrames) {
      final inSeason = f.season == todaysSeason;
      expect(profile.isFrameUnlocked(f), inSeason,
          reason:
              '${f.id} (season ${f.season}) should be ${inSeason ? "" : "not "}'
              'unlockable today (season $todaysSeason)');
      // Claiming follows the same gate.
      expect(await profile.claimFrame(f), inSeason,
          reason: '${f.id} claim should match the season gate');
    }

    // At most one of the two seasonal frames can be in-season at once, and the
    // other must be locked — proving the gate actually discriminates.
    final unlocked =
        seasonalFrames.where(profile.isFrameUnlocked).map((f) => f.id).toList();
    expect(unlocked.length, lessThanOrEqualTo(1));
  });

  test('a non-seasonal frame is unaffected by the season gate', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    // 'sky' is always-free (null unlock, cost 0, no season) — still unlocked.
    final sky = AvatarFrames.byId('sky');
    expect(sky.season, isNull);
    expect(profile.isFrameUnlocked(sky), isTrue);

    // 'stars' is gated on pet level only; season plays no part.
    final stars = AvatarFrames.byId('stars');
    expect(stars.season, isNull);
    expect(profile.isFrameUnlocked(stars), isFalse);
    await profile.addPetXp(100000);
    expect(profile.isFrameUnlocked(stars), isTrue);
  });
}
