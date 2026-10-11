// Verifies the HIDDEN admin panel entry point: a long-press on the hub footer
// "Made with AI 🤖" text opens the Admin / Dev Tools screen. There is no
// visible button, so the gesture is the only way in.
//
// The reloadApp() helper is a no-op under flutter test (admin_reload_stub), so
// nothing tries to reload the page here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/brain_buddies_app.dart';

void main() {
  testWidgets('hidden long-press on the footer opens the admin screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // The footer sits at the very bottom of the scrolling hub; scroll it in.
    await tester.dragUntilVisible(
      find.text('Made with AI 🤖'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    // No visible admin button exists yet.
    expect(find.text('Admin / Dev Tools'), findsNothing);

    // Long-press the hidden gesture target.
    await tester.longPress(find.text('Made with AI 🤖'));
    await tester.pumpAndSettle();

    // The admin panel is now open.
    expect(find.text('Admin / Dev Tools'), findsOneWidget);
    expect(find.text('Reset Everything'), findsOneWidget);
  });
}
