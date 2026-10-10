import 'package:brain_buddies/core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AnalyticsService records aggregate counters and persists them',
      () async {
    SharedPreferences.setMockInitialValues({});
    final analytics = AnalyticsService();
    await analytics.load();

    analytics.recordGameOpened('number_quest');
    analytics.recordGameOpened('number_quest');
    analytics.recordRound(correct: 3, threeStars: true, bossBeaten: false);
    await analytics.updateSnapshots(streak: 2, petLevel: 4, coins: 120);

    // In-memory aggregates reflect the counts.
    expect(analytics.opensFor('number_quest'), 2);
    expect(analytics.roundsTotal, 1);
    expect(analytics.correctTotal, 3);
    expect(analytics.threeStarTotal, 1);
    expect(analytics.bossTotal, 0);
    expect(analytics.snapshotStreak, 2);
    expect(analytics.snapshotPetLevel, 4);
    expect(analytics.snapshotCoins, 120);

    // A fresh instance reads the persisted values back.
    final reloaded = AnalyticsService();
    await reloaded.load();
    expect(reloaded.opensFor('number_quest'), 2);
    expect(reloaded.roundsTotal, 1);
    expect(reloaded.correctTotal, 3);
    expect(reloaded.threeStarTotal, 1);
    expect(reloaded.bossTotal, 0);
    expect(reloaded.snapshotStreak, 2);
    expect(reloaded.snapshotPetLevel, 4);
    expect(reloaded.snapshotCoins, 120);

    // Only 'analytics_'-prefixed keys are written (no PII, no stray keys).
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isNotEmpty);
    expect(prefs.getKeys().every((k) => k.startsWith('analytics_')), isTrue);
  });
}
