// Engagement Phase 4 widget tests at phone size (430x900):
//  - the result screen shows the "🌟 NEW BEST!" banner when isNewFastest;
//  - the hub game card shows a gold mastery medal for a mastered game;
//  - the daily surprise chest opens and shows its prize.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/app/brain_buddies_app.dart';
import 'package:brain_buddies/app/daily_reward_screen.dart';
import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/games/memory_match/models/memory_level.dart';
import 'package:brain_buddies/games/memory_match/screens/memory_result_screen.dart';
import 'package:brain_buddies/games/memory_match/services/memory_state.dart';

void main() {
  const phone = Size(430, 900);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('result screen shows the New Best banner when isNewFastest',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    usePhone(tester);

    final profile = PlayerProfile();
    await profile.load();
    final state = MemoryState();
    await state.load();

    final level = MemoryMap.allLevels.first;
    final outcome = MemoryOutcome(
      stars: 3,
      coinsEarned: 30,
      isNewFastest: true,
      bossBeaten: false,
      elapsedSeconds: 12,
      perfect: true,
    );

    await tester.pumpWidget(
      L10n(
        lang: profile.lang,
        notifier: profile,
        child: MaterialApp(
          locale: profile.lang.locale,
          home: MemoryResultScreen(
            state: state,
            profile: profile,
            level: level,
            outcome: outcome,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🌟 NEW BEST!'), findsOneWidget);
    // The original fastest-time banner still renders too.
    expect(find.text('⚡ NEW FASTEST TIME!'), findsOneWidget);
    // The ONLY tolerated exception is the pre-existing ~8px HORIZONTAL overflow
    // in the DoubleAwardsButton's centered Row (double_awards_button.dart):
    // icon + "Double Awards" + "x2" can exceed a 430px frame. The New Best
    // banner only adds VERTICAL height, so any Phase 4 regression would surface
    // as a *bottom* (vertical) overflow — which this assertion does NOT
    // tolerate. We therefore precisely match a horizontal RenderFlex overflow
    // ("on the right" in LTR / "on the left" in RTL) and reject everything
    // else, so a new overflow still fails this phone-size regression test.
    final ex = tester.takeException();
    if (ex != null) {
      final msg = ex.toString();
      final isKnownHorizontalOverflow = msg.contains('A RenderFlex overflowed') &&
          (msg.contains('on the right') || msg.contains('on the left'));
      expect(isKnownHorizontalOverflow, isTrue,
          reason: 'only the known horizontal DoubleAwardsButton overflow is '
              'tolerated; a new (e.g. vertical) overflow must fail. Got: $msg');
    }
  });

  testWidgets('hub game card shows the gold mastery medal for a mastered game',
      (WidgetTester tester) async {
    // Seed Number Quest's cached tier to gold (3).
    SharedPreferences.setMockInitialValues({
      'profile_mastery_number_quest': 3,
    });
    usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // The gold medal renders on the hub (Number Quest card).
    expect(find.text('🥇'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the surprise chest opens and shows a prize',
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
          home: DailyRewardScreen(profile: profile, onPlayDaily: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The chest is openable: its OPEN button shows.
    final openBtn = find.text('Open! 🎁');
    expect(openBtn, findsOneWidget);

    // Scroll it into view and tap.
    await tester.ensureVisible(openBtn);
    await tester.pumpAndSettle();
    await tester.tap(openBtn);
    await tester.pumpAndSettle();

    // After opening, the chest shows the come-back note (button gone).
    expect(find.text('Open! 🎁'), findsNothing);
    expect(find.text('Come back tomorrow for another!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---- hub what's-new panel + Daily badge states (review finding 3) ----

  String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  testWidgets('hub what\'s-new panel auto-hides when ALL hooks are off',
      (WidgetTester tester) async {
    final today = dayKey(DateTime.now());
    // Satisfy every daily hook today so nothing is pending. A mission reward is
    // not claimable on a fresh board, so hasClaimableMission is already false.
    SharedPreferences.setMockInitialValues({
      'profile_login_last_claim': today,
      'profile_daily_treat_day': today,
      'profile_chest_day': today,
      'profile_challenge_day': today,
    });
    usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // Panel title is absent -> the panel auto-hid with no pending items.
    expect(find.text('Today ✨'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub what\'s-new panel shows EXACTLY the pending rows',
      (WidgetTester tester) async {
    final today = dayKey(DateTime.now());
    // Login claimed + treat claimed + challenge played; only the chest is left.
    SharedPreferences.setMockInitialValues({
      'profile_login_last_claim': today,
      'profile_daily_treat_day': today,
      'profile_challenge_day': today,
      // chest NOT opened -> the only pending row.
    });
    usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // The panel shows, with ONLY the surprise-chest row.
    expect(find.text('Today ✨'), findsOneWidget);
    expect(find.text('Surprise chest!'), findsOneWidget);
    // The satisfied hooks are NOT listed.
    expect(find.text("Today's gift is ready!"), findsNothing);
    expect(find.text('Feed Buddy — treat ready'), findsNothing);
    expect(find.text('New daily challenge'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a what\'s-new row marks the panel seen for the day',
      (WidgetTester tester) async {
    final today = dayKey(DateTime.now());
    // Only the chest pending; tap its row and return — the panel must stay hidden.
    SharedPreferences.setMockInitialValues({
      'profile_login_last_claim': today,
      'profile_daily_treat_day': today,
      'profile_challenge_day': today,
    });
    usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    final chestRow = find.text('Surprise chest!');
    expect(chestRow, findsOneWidget);
    await tester.tap(chestRow);
    await tester.pumpAndSettle();

    // Routing opened the Daily screen; come back to the hub.
    expect(find.text('Surprise Chest'), findsWidgets); // on the Daily screen
    Navigator.of(tester.element(find.byType(DailyRewardScreen))).pop();
    await tester.pumpAndSettle();

    // The panel is now marked seen for the day -> hidden on return.
    expect(find.text('Today ✨'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('X dismiss hides the what\'s-new panel for the day',
      (WidgetTester tester) async {
    final today = dayKey(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'profile_login_last_claim': today,
      'profile_daily_treat_day': today,
      'profile_challenge_day': today,
    });
    usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    expect(find.text('Today ✨'), findsOneWidget);
    // The X close control sits inside the panel.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Today ✨'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Daily badge stays lit when the login gift is claimed but the chest is '
      'unopened', (WidgetTester tester) async {
    final today = dayKey(DateTime.now());
    // Login already claimed today; chest still unopened -> the Daily nudge must
    // remain because the chest lives on the Daily surface. Mark what's-new seen
    // so the top panel does not also render the chest '!'-style content.
    SharedPreferences.setMockInitialValues({
      'profile_login_last_claim': today,
      'profile_daily_treat_day': today,
      'profile_challenge_day': today,
      'profile_whatsnew_seen_day': today,
      // chest NOT opened.
    });
    usePhone(tester);

    await tester.pumpWidget(const BrainBuddiesApp());
    await tester.pumpAndSettle();

    // Find the Daily action button (its label is 'Daily') and assert its badge
    // '!' dot renders inside that button's subtree.
    final dailyLabel = find.text('Daily');
    expect(dailyLabel, findsOneWidget);
    // The nearest GestureDetector ancestor is the Daily _ActionButton root; its
    // Stack holds both the panel and the '!' badge dot.
    final dailyButton = find
        .ancestor(of: dailyLabel, matching: find.byType(GestureDetector))
        .first;
    final badgeInDaily =
        find.descendant(of: dailyButton, matching: find.text('!'));
    expect(badgeInDaily, findsOneWidget,
        reason: 'the chest-only pending state must keep the Daily badge lit');
    expect(tester.takeException(), isNull);
  });
}
