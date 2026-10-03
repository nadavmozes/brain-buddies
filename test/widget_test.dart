// Smoke test for BrainBuddies.
//
// Verifies the hub renders with the game grid and that opening Number Quest
// navigates into the game's home screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/brain_buddies_app.dart';

void main() {
  testWidgets('Hub shows title and games, opens Number Quest',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Use a phone-sized surface so layout matches a real device.
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // Hub title and the Number Quest card are visible.
    expect(find.text('BrainBuddies'), findsOneWidget);
    expect(find.text('Number Quest'), findsOneWidget);

    // Open Number Quest.
    await tester.tap(find.text('Number Quest'));
    await tester.pumpAndSettle();

    // Number Quest home shows its banner and Play button.
    expect(find.text('NUMBER'), findsOneWidget);
    expect(find.text('QUEST'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });

  testWidgets('Hub opens Shape Safari', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    expect(find.text('Shape Safari'), findsOneWidget);

    await tester.tap(find.text('Shape Safari'));
    await tester.pumpAndSettle();

    // Shape Safari home shows its banner and the habitat select.
    expect(find.text('SHAPE'), findsOneWidget);
    expect(find.text('SAFARI'), findsOneWidget);
    expect(find.text('Jungle Trail'), findsOneWidget);

    // Opening a habitat shows its trail map.
    await tester.tap(find.text('Jungle Trail'));
    await tester.pumpAndSettle();
    expect(find.text('🌿 Jungle Trail'), findsOneWidget);
  });

  testWidgets('Hub opens Word Wizard and Clock Hero',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    expect(find.text('Word Wizard'), findsOneWidget);
    await tester.tap(find.text('Word Wizard'));
    await tester.pumpAndSettle();
    expect(find.text('WORD'), findsOneWidget);
    expect(find.text('WIZARD'), findsOneWidget);

    // Back to hub, then open Clock Hero.
    await tester.tap(find.text('All Games'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clock Hero'));
    await tester.pumpAndSettle();
    expect(find.text('CLOCK'), findsOneWidget);
    expect(find.text('HERO'), findsOneWidget);

    // Clock Hero home is a world select; open the Morning trail map.
    expect(find.text('Morning Trail'), findsOneWidget);
    await tester.tap(find.text('Morning Trail'));
    await tester.pumpAndSettle();
    expect(find.text('🌅 Morning Trail'), findsOneWidget);
  });

  testWidgets('Hub opens the shared Avatar Shop with a premium coming-soon',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // Open the hub-level shop.
    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    expect(find.text('Avatar Shop'), findsOneWidget);
    // The free starter avatar is equipped by default.
    expect(find.text('Equipped ✓'), findsOneWidget);

    // The premium avatar is last; scroll to reveal it, then check it shows
    // its price and a "Coming Soon" label.
    await tester.dragUntilVisible(
      find.text('Coming Soon'),
      find.byType(GridView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coming Soon'), findsOneWidget);
    expect(find.text('\$1.99'), findsOneWidget);
  });
}
