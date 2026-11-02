// Engagement Phase 5 / P8 widget test at phone size (430x900): the sticker
// shelf (second tab of the achievements screen) renders earned stickers with
// their emoji and locked ones with '🔒', without a layout exception.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/achievements_screen.dart';
import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/models/sticker.dart';
import 'package:brain_buddies/core/services/player_profile.dart';

void main() {
  const phone = Size(430, 900);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('sticker shelf shows earned emoji and locked lock icons',
      (WidgetTester tester) async {
    // Seed ownership of two stickers so the shelf has both earned + locked.
    SharedPreferences.setMockInitialValues({
      'profile_owned_stickers': const ['star_sticker', 'rainbow_sticker'],
    });
    usePhone(tester);

    final profile = PlayerProfile();
    await profile.load();
    expect(profile.hasSticker('star_sticker'), isTrue);

    await tester.pumpWidget(
      L10n(
        lang: profile.lang,
        notifier: profile,
        child: MaterialApp(
          locale: profile.lang.locale,
          home: AchievementsScreen(profile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to the Stickers tab (second tab).
    await tester.tap(find.text(profile.lang.isRtl ? 'מדבקות' : 'Stickers'));
    await tester.pumpAndSettle();

    // Earned stickers render their emoji.
    expect(find.text(Stickers.byId('star_sticker').emoji), findsOneWidget);
    expect(find.text(Stickers.byId('rainbow_sticker').emoji), findsOneWidget);

    // At least one locked sticker shows the lock glyph.
    final lockedCount = Stickers.all.length - profile.ownedStickers.length;
    expect(lockedCount, greaterThan(0));
    expect(find.text('🔒'), findsWidgets);

    // Both grids lay out cleanly at phone size (no overflow exception).
    expect(tester.takeException(), isNull);
  });
}
