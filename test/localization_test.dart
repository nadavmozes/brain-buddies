// Phase 1 localization tests: the Hebrew default (via a persisted lang),
// right-to-left Directionality under Hebrew, and the live EN ⇄ עב toggle.
//
// These complement the English-asserting tests (which must stay green because
// the default under `flutter test` is en: the test platform locale is en_US
// and no 'profile_lang' key is seeded unless a test sets one).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/brain_buddies_app.dart';
import 'package:brain_buddies/core/l10n/app_strings.dart';

const _he = HeStrings();
const _en = EnStrings();

void main() {
  testWidgets('persisted profile_lang=he renders Hebrew chrome in RTL',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'profile_lang': 'he'});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // (a) A known Hebrew chrome string renders (the hub tagline).
    expect(find.text(_he.hubTagline), findsOneWidget);
    // The English tagline is NOT shown.
    expect(find.text(_en.hubTagline), findsNothing);

    // (b) The whole tree is right-to-left under Hebrew.
    final dir = Directionality.of(
        tester.element(find.text(_he.hubTagline)));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('default (no lang key, en_US env) stays English + LTR',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    expect(find.text(_en.hubTagline), findsOneWidget);
    final dir = Directionality.of(
        tester.element(find.text(_en.hubTagline)));
    expect(dir, TextDirection.ltr);
  });

  testWidgets('the language toggle switches chrome live EN -> עב',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // Starts English.
    expect(find.text(_en.hubTagline), findsOneWidget);

    // The toggle pill shows the OTHER language's code ("עב" while in English).
    expect(find.text(_en.languageToggleLabel), findsOneWidget);
    await tester.tap(find.text(_en.languageToggleLabel));
    await tester.pumpAndSettle();

    // Now Hebrew chrome is shown and the tree flipped to RTL.
    expect(find.text(_he.hubTagline), findsOneWidget);
    final dir = Directionality.of(
        tester.element(find.text(_he.hubTagline)));
    expect(dir, TextDirection.rtl);
  });
}
