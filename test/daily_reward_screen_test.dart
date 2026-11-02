// Widget test for the Engagement Phase 1 Daily surface at phone size (430x900):
// the hub Daily button shows the "!" badge when a login gift is claimable, and
// opening it renders the 7-box login calendar in a claimable state plus the
// play-all-6 tracker and the "Play today's challenge" button.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/brain_buddies_app.dart';
import 'package:brain_buddies/core/models/daily_reward.dart';

void main() {
  testWidgets('hub Daily badge + DailyRewardScreen renders 7 boxes claimable',
      (WidgetTester tester) async {
    // A fresh profile has an unclaimed gift, so the badge should show.
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // Scroll the Daily button into view.
    await tester.dragUntilVisible(
      find.text('Daily'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    // The red "!" badge renders next to the Daily button (fresh gift pending).
    expect(find.text('!'), findsWidgets);

    // Open the Daily surface.
    await tester.tap(find.text('Daily'));
    await tester.pumpAndSettle();

    // The 7-day calendar shows all seven day labels.
    for (var i = 1; i <= DailyRewards.length; i++) {
      expect(find.text('Day $i'), findsOneWidget);
    }

    // Claimable state: a CLAIM button is present, plus the play-all-6 tracker
    // and the challenge button.
    expect(find.text('Claim'), findsOneWidget);
    expect(find.text('Play all 6 today!'), findsOneWidget);
    expect(find.text("Play today's challenge"), findsOneWidget);

    // Claiming the gift pays coins and swaps the button for the come-back note.
    await tester.tap(find.text('Claim'));
    await tester.pumpAndSettle();
    expect(find.text('Come back tomorrow!'), findsOneWidget);
  });
}
