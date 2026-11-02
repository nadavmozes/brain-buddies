// Engagement Phase 2 — Avatar Frames widget tests at phone size (430x900):
//  - The shop Frames tab renders frame cards and an always-free frame can be
//    equipped (its pill flips to "Equipped ✓").
//  - The hub profile bar renders an AvatarBadge with a selected frame's ring
//    without throwing a layout/overflow exception at 430px.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/brain_buddies_app.dart';
import 'package:brain_buddies/app/shop_screen.dart';
import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/models/avatar_frame.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/core/widgets/avatar_badge.dart';

void main() {
  const phone = Size(430, 900);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shop Frames tab renders and an always-free frame can be equipped',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    usePhone(tester);

    final profile = PlayerProfile();
    await profile.load();

    await tester.pumpWidget(
      L10n(
        lang: profile.lang,
        notifier: profile,
        child: MaterialApp(
          locale: profile.lang.locale,
          home: ShopScreen(profile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to the Frames tab.
    await tester.tap(find.text('Frames'));
    await tester.pumpAndSettle();

    // The default 'none' frame is equipped by default.
    expect(find.text('None'), findsOneWidget);
    expect(find.text('Equipped ✓'), findsOneWidget);

    // The always-free 'Sky' frame shows a CLAIM gift pill; claim + auto-equip.
    expect(find.text('Sky'), findsOneWidget);
    expect(find.text('CLAIM 🎁'), findsWidgets);

    await tester.tap(find.text('CLAIM 🎁').first);
    await tester.pumpAndSettle();

    // Sky is now owned+equipped in the profile.
    expect(profile.ownsFrame('sky'), isTrue);
    expect(profile.selectedFrameId, 'sky');

    // No layout exception at phone width.
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub profile bar renders the AvatarBadge ring without overflow',
      (WidgetTester tester) async {
    // Seed a selected frame so the ring is drawn in the hub profile bar.
    SharedPreferences.setMockInitialValues({
      'profile_owned_frames': const ['rainbow'],
      'profile_selected_frame': 'rainbow',
    });
    usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // The profile-bar badge renders (there may be additional badges elsewhere,
    // e.g. the shop preview is not on the hub, so exactly one here).
    expect(find.byType(AvatarBadge), findsOneWidget);

    final badge = tester.widget<AvatarBadge>(find.byType(AvatarBadge));
    expect(badge.frame.id, 'rainbow');
    expect(badge.frame.hasRing, isTrue);

    // No overflow / layout exception at 430px with the ring drawn.
    expect(tester.takeException(), isNull);
  });

  testWidgets('AvatarFrames catalog is self-consistent', (tester) async {
    // The default frame has no ring; every gated frame carries a label.
    expect(AvatarFrames.byId('none').hasRing, isFalse);
    for (final f in AvatarFrames.all) {
      if (f.unlock != null) {
        expect(f.unlock!.label, isNotEmpty, reason: '${f.id} needs a label');
      }
    }
  });
}
