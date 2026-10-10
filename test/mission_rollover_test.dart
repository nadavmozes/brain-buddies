import 'package:brain_buddies/core/models/mission.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reportMission rolls over stale mission day before applying', () async {
    final today = _dayKey(DateTime.now());
    final yesterday =
        _dayKey(DateTime.now().subtract(const Duration(days: 1)));

    // Seed stale mission state belonging to yesterday.
    SharedPreferences.setMockInitialValues({
      'profile_mission_day': yesterday,
      'profile_mission_progress': ['boss_1:5', 'finish_3:2'],
      'profile_mission_claimed': ['boss_1'],
    });

    final profile = PlayerProfile();
    await profile.load();

    // Reporting after midnight should roll the board over first, then apply.
    await profile.reportMission(MissionMetric.correctAnswers, 1);

    // Stale progress for yesterday's ids is gone.
    expect(profile.missionProgress('boss_1'), 0);
    expect(profile.missionProgress('finish_3'), 0);
    expect(profile.missionClaimed('boss_1'), isFalse);

    // The persisted mission day is now today.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_mission_day'), today);

    // Only today's missions matching the reported metric advanced (by 1).
    for (final m in profile.todaysMissions) {
      if (m.metric == MissionMetric.correctAnswers) {
        expect(profile.missionProgress(m.id), 1);
      } else {
        expect(profile.missionProgress(m.id), 0);
      }
    }
  });

  test('Missions.forDay returns a stable 3-mission list across calls', () {
    final fixed = DateTime(2024, 6, 15);
    final first = Missions.forDay(fixed);
    final second = Missions.forDay(fixed);

    expect(first.length, 3);
    expect(second.length, 3);
    expect(first.map((m) => m.id).toList(),
        second.map((m) => m.id).toList());
  });
}
