// Widget tests for the Engagement Phase 1 Daily surface at phone size
// (430x900):
//  - English: the hub Daily button shows the "!" badge when a login gift is
//    claimable, and opening it renders the 7-box login calendar in a claimable
//    state plus the play-all-6 tracker (6 game dots) and the challenge button.
//  - Hebrew (RTL): the Daily surface renders localized labels right-to-left
//    without layout exceptions at 430x900.
//  - The hub "Welcome back!" comeback card renders when a gift is pending.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/brain_buddies_app.dart';
import 'package:brain_buddies/app/daily_reward_screen.dart';
import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/models/daily_reward.dart';
import 'package:brain_buddies/core/models/game_catalog.dart';
import 'package:brain_buddies/core/services/player_profile.dart';

void main() {
  const phone = Size(430, 900);

  void _usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('hub Daily badge + DailyRewardScreen renders 7 boxes claimable',
      (WidgetTester tester) async {
    // A fresh profile has an unclaimed gift, so the badge should show.
    SharedPreferences.setMockInitialValues({});
    _usePhone(tester);

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

    // The play-all-6 tracker renders a dot for every game (6 lit/unlit dots).
    for (final game in GameCatalog.all) {
      expect(find.text(game.emoji), findsWidgets,
          reason: '${game.id} dot should render');
    }

    // Claimable state: a CLAIM button is present, plus the play-all-6 tracker
    // and the challenge button.
    expect(find.text('Claim'), findsOneWidget);
    expect(find.text('Play all 6 today!'), findsOneWidget);
    expect(find.text("Play today's challenge"), findsOneWidget);

    // Before claiming, no box is marked completed yet.
    expect(find.text('✅'), findsNothing);

    // Claiming the gift pays coins and swaps the button for the come-back note.
    await tester.tap(find.text('Claim'));
    await tester.pumpAndSettle();
    expect(find.text('Come back tomorrow!'), findsOneWidget);

    // Ordinary-day post-claim state: exactly the day-1 box reads as completed
    // (one ✅), and tomorrow's box is NOT highlighted as today/claimable (no
    // CLAIM button). This guards against the calendar jumping a day ahead.
    expect(find.text('Claim'), findsNothing);
    expect(find.text('✅'), findsOneWidget);
  });

  testWidgets('day-7 post-claim shows all boxes completed, not reset',
      (WidgetTester tester) async {
    // Seed the cycle at the final day (index 6), unclaimed so day 7 is
    // claimable. Claiming day 7 wraps the cycle index back to 0, which must NOT
    // wipe the completed markers for the rest of the day.
    SharedPreferences.setMockInitialValues({
      'profile_login_cycle': DailyRewards.length - 1,
    });
    _usePhone(tester);

    final profile = PlayerProfile();
    await profile.load();

    await tester.pumpWidget(
      L10n(
        lang: profile.lang,
        notifier: profile,
        child: MaterialApp(
          locale: profile.lang.locale,
          home: DailyRewardScreen(profile: profile, onPlayDaily: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Day 7 is claimable: the CLAIM button shows and the six earlier boxes read
    // as completed.
    expect(find.text('Claim'), findsOneWidget);
    expect(find.text('✅'), findsNWidgets(DailyRewards.length - 1));

    await tester.tap(find.text('Claim'));
    await tester.pumpAndSettle();

    // After the day-7 claim the cycle wraps to index 0, but all seven boxes
    // must remain completed for the rest of the day (not reset to an empty
    // calendar presenting day 1 as today).
    expect(find.text('Come back tomorrow!'), findsOneWidget);
    expect(find.text('Claim'), findsNothing);
    expect(find.text('✅'), findsNWidgets(DailyRewards.length));
  });

  testWidgets('DailyRewardScreen renders RTL in Hebrew at 430x900',
      (WidgetTester tester) async {
    // Force Hebrew via the persisted language key; seed a full all-six set so
    // the Hebrew "claim bonus" button renders too.
    SharedPreferences.setMockInitialValues({
      'profile_lang': 'he',
      'profile_allsix_day': _todayKey(),
      'profile_allsix_set': GameCatalog.all.map((g) => g.id).toList(),
    });
    _usePhone(tester);

    final profile = PlayerProfile();
    await profile.load();

    await tester.pumpWidget(
      L10n(
        lang: profile.lang,
        notifier: profile,
        child: MaterialApp(
          locale: profile.lang.locale,
          // Drive directionality from the language exactly as the real app's
          // MaterialApp.builder does, so the RTL assertion mirrors production.
          builder: (context, child) => Directionality(
            textDirection: profile.lang.direction,
            child: child!,
          ),
          home: DailyRewardScreen(profile: profile, onPlayDaily: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The screen is laid out right-to-left.
    expect(Directionality.of(tester.element(find.byType(DailyRewardScreen))),
        TextDirection.rtl);

    // Localized Hebrew labels render (title + play-all-6 title + claim bonus).
    expect(find.text('מתנה יומית'), findsWidgets);
    expect(find.text('שחקו בכל 6 היום!'), findsOneWidget);
    expect(find.text('קבלו בונוס 🪙 40'), findsOneWidget);

    // No overflow / layout exception was thrown at phone width.
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub shows the Welcome back card when a comeback gift is pending',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'profile_comeback_pending': true,
    });
    _usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // The friendly English welcome-back card is visible on the hub.
    expect(find.text('Welcome back! 🎁'), findsOneWidget);
    expect(find.text('Get gift 🎁'), findsOneWidget);
  });
}

String _todayKey() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
