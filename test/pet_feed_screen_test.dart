// Widget tests for the Engagement Phase 3 UI at phone size (430x900):
//  - PetScreen renders the treat count + Feed button; tapping Feed spends a
//    treat without throwing.
//  - DailyRewardScreen renders the weekly-goal panel + claim button when the
//    weekly goal is met, with no 430px overflow.
//  - Hebrew (RTL): the pet feed UI renders localized labels right-to-left
//    without a layout exception.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/daily_reward_screen.dart';
import 'package:brain_buddies/app/pet_screen.dart';
import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/services/player_profile.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _weekKeyNow() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return 'W${_dayKey(monday)}';
}

Widget _wrap(PlayerProfile profile, Widget home) {
  return L10n(
    lang: profile.lang,
    notifier: profile,
    child: MaterialApp(
      locale: profile.lang.locale,
      builder: (context, child) => Directionality(
        textDirection: profile.lang.direction,
        child: child!,
      ),
      home: home,
    ),
  );
}

void main() {
  const phone = Size(430, 900);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('PetScreen shows treat count + Feed button and feeding works',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'profile_pet_treats': 2});
    usePhone(tester);

    final profile = PlayerProfile();
    await profile.load();

    await tester.pumpWidget(_wrap(profile, PetScreen(profile: profile)));
    await tester.pumpAndSettle();

    // Treat count row renders (🦴 2) and the Feed button is present.
    expect(find.text('🦴 2'), findsOneWidget);
    expect(find.text('Feed Buddy'), findsWidgets);

    // Feeding spends a treat (count becomes 1) with no exception.
    await tester.tap(find.text('Feed Buddy').last);
    await tester.pump(); // apply state change
    expect(profile.petTreats, 1);
    expect(find.text('🦴 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DailyRewardScreen renders the weekly panel + claim at 430x900',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'profile_week_key': _weekKeyNow(),
      'profile_week_days_played': 5,
      'profile_week_claimed': false,
    });
    usePhone(tester);

    final profile = PlayerProfile();
    await profile.load();

    await tester.pumpWidget(
      _wrap(profile, DailyRewardScreen(profile: profile, onPlayDaily: () {})),
    );
    await tester.pumpAndSettle();

    // The weekly-goal panel + progress + claim button render.
    expect(find.text('Weekly Goal'), findsOneWidget);
    expect(find.text('5 / 5 days'), findsOneWidget);
    expect(find.text('Claim 🪙 40 + 🦴'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Claiming pays and swaps to the claimed note. Scroll the button into view
    // first (the panel can sit below the fold at phone height).
    await tester.ensureVisible(find.text('Claim 🪙 40 + 🦴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Claim 🪙 40 + 🦴'));
    await tester.pumpAndSettle();
    expect(profile.coins, 40);
    expect(find.text('Claimed ✓'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PetScreen renders RTL Hebrew feed labels at 430x900',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'profile_lang': 'he',
      'profile_pet_treats': 1,
    });
    usePhone(tester);

    final profile = PlayerProfile();
    await profile.load();

    await tester.pumpWidget(_wrap(profile, PetScreen(profile: profile)));
    await tester.pumpAndSettle();

    // Laid out right-to-left.
    expect(Directionality.of(tester.element(find.byType(PetScreen))),
        TextDirection.rtl);

    // Localized Hebrew feed label + treat count render without overflow.
    expect(find.text('האכילו את החבר'), findsWidgets);
    expect(find.text('🦴 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
