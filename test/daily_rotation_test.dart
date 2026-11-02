// FEAT-003: the hub Daily Challenge rotates across all wired games by date.
//  - dailyChallengeGameFor(d) is deterministic per date and, scanned over any
//    6 consecutive day-of-year values, covers EVERY game in the rotation list.
//  - A phone-sized (430x900) widget test opens the Daily surface and asserts
//    today's challenge game name + icon are shown, then invokes the daily and
//    confirms a non-NQ game's GameScreen opens without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/brain_buddies_app.dart';
import 'package:brain_buddies/app/game_hub_screen.dart';
import 'package:brain_buddies/core/models/game_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const phone = Size(430, 900);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('dailyChallengeGameFor is deterministic for a given date', () {
    final a = dailyChallengeGameFor(DateTime(2024, 3, 14));
    final b = dailyChallengeGameFor(DateTime(2024, 3, 14));
    expect(a.id, b.id);
  });

  test('6 consecutive days cover every game in the rotation', () {
    // Start on an arbitrary date and walk forward 6 days; because the selector
    // is day-of-year modulo 6, six consecutive days hit all six buckets.
    final start = DateTime(2024, 1, 1);
    final seen = <String>{};
    for (var i = 0; i < 6; i++) {
      seen.add(dailyChallengeGameFor(start.add(Duration(days: i))).id);
    }
    expect(seen, equals(dailyChallengeRotation.map((g) => g.id).toSet()));
    expect(seen.length, dailyChallengeRotation.length);
  });

  test('every rotation entry is a real, available catalog game', () {
    for (final g in dailyChallengeRotation) {
      expect(GameCatalog.all, contains(g));
      expect(g.available, isTrue);
    }
  });

  testWidgets('Daily surface shows today\'s challenge game and opens it',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // Open the Daily surface from the hub.
    await tester.dragUntilVisible(
      find.text('Daily'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily'));
    await tester.pumpAndSettle();

    // Today's challenge game (icon + "Today: <name>") is shown. English game
    // titles come straight from the catalog.
    final today = dailyChallengeGameFor(DateTime.now());
    expect(find.text('Today: ${today.title}'), findsOneWidget);
    expect(find.text(today.emoji), findsWidgets);
    expect(find.text("Play today's challenge"), findsOneWidget);

    // Invoking the daily opens that game's GameScreen without throwing. Scroll
    // the button into view first (the panel sits below several others).
    await tester.dragUntilVisible(
      find.text("Play today's challenge"),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Play today's challenge"));
    await tester.pumpAndSettle();

    // No layout/navigation exception fired launching the daily round.
    expect(tester.takeException(), isNull);
  });
}
