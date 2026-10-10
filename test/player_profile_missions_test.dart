// Locks in the daily-mission mechanics in PlayerProfile: deterministic board,
// clamped reporting that ignores non-matching metrics, claim-once payouts, and
// the midnight rollover. Complements test/mission_rollover_test.dart (which
// covers the rollover-before-report path) by focusing on clamp + claim-once.

import 'package:brain_buddies/core/models/mission.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Returns a metric NOT used by any of today's missions, or null if every
/// metric is in play. Used to prove non-matching reports are ignored.
MissionMetric? _unusedMetric(List<MissionDef> missions) {
  final used = missions.map((m) => m.metric).toSet();
  for (final m in MissionMetric.values) {
    if (!used.contains(m)) return m;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Missions.forDay is deterministic for a fixed day', () {
    final day = DateTime(2025, 3, 9);
    final a = Missions.forDay(day);
    final b = Missions.forDay(day);
    expect(a.length, 3);
    expect(b.length, 3);
    expect(a.map((m) => m.id).toList(), b.map((m) => m.id).toList());
    // Three distinct missions (no duplicate pulled from the pool).
    expect(a.map((m) => m.id).toSet().length, 3);
  });

  test('reportMission clamps to target and ignores other metrics', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    final missions = profile.todaysMissions;
    final target = missions.first;

    // Over-report by a wide margin; progress must cap at the target.
    await profile.reportMission(target.metric, target.target + 100);
    // Every mission with this metric is clamped (there may be more than one).
    for (final m in missions) {
      if (m.metric == target.metric) {
        expect(profile.missionProgress(m.id), m.target);
        expect(profile.missionComplete(m), isTrue);
      }
    }

    // A metric no mission tracks today leaves all progress untouched.
    final unused = _unusedMetric(missions);
    if (unused != null) {
      final before = {for (final m in missions) m.id: profile.missionProgress(m.id)};
      await profile.reportMission(unused, 5);
      for (final m in missions) {
        expect(profile.missionProgress(m.id), before[m.id]);
      }
    }
  });

  test('claimMission pays exactly once and only when complete', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    final mission = profile.todaysMissions.first;
    final startCoins = profile.coins;

    // Not yet complete -> nothing paid.
    expect(await profile.claimMission(mission), 0);
    expect(profile.coins, startCoins);

    // Complete it by reporting exactly its target for its metric.
    await profile.reportMission(mission.metric, mission.target);
    expect(profile.missionComplete(mission), isTrue);

    // First claim pays the reward and raises coins.
    final paid = await profile.claimMission(mission);
    expect(paid, mission.rewardCoins);
    expect(profile.coins, startCoins + mission.rewardCoins);
    expect(profile.missionClaimed(mission.id), isTrue);

    // Second claim pays nothing more.
    expect(await profile.claimMission(mission), 0);
    expect(profile.coins, startCoins + mission.rewardCoins);
  });

  test('a stale mission day rolls over on the next report', () async {
    final yesterday =
        _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final today = _dayKey(DateTime.now());

    // Seed yesterday's board with progress + a claim.
    SharedPreferences.setMockInitialValues({
      'profile_mission_day': yesterday,
      'profile_mission_progress': ['answer_15:15', 'boss_1:1'],
      'profile_mission_claimed': ['answer_15'],
    });

    final profile = PlayerProfile();
    await profile.load();

    // Reporting after midnight clears yesterday's state first.
    await profile.reportMission(MissionMetric.correctAnswers, 1);

    expect(profile.missionProgress('answer_15'), 0);
    expect(profile.missionProgress('boss_1'), 0);
    expect(profile.missionClaimed('answer_15'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_mission_day'), today);
  });
}
