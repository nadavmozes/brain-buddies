// FEAT-002 (plan.md I.3): a game screen's in-round header must show the Hebrew
// stop/guardian title in Hebrew mode (matching the trail screens), with no raw
// English 'Stop N' / 'Guardian' / English guardian name leaking. Pumps under an
// L10n(he) ancestor at a 430x900 phone surface, mirroring the Word Wizard
// Hebrew test scaffolding.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/core/theme/app_theme.dart';
import 'package:brain_buddies/games/clock_hero/models/time_world.dart';
import 'package:brain_buddies/games/clock_hero/screens/clock_game_screen.dart';
import 'package:brain_buddies/games/clock_hero/services/clock_state.dart';

final _hebrew = RegExp(r'[\u0590-\u05FF]');

void main() {
  Future<void> pumpClock(
    WidgetTester tester,
    ClockLevel level, {
    required ClockState state,
    required PlayerProfile profile,
  }) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        locale: const Locale('he'),
        supportedLocales: const [Locale('en'), Locale('he')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: L10n(
          lang: AppLang.he,
          notifier: profile,
          child: ClockGameScreen(
            state: state,
            profile: profile,
            level: level,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Finds a Text whose data contains [needle].
  Finder textContaining(String needle) => find.byWidgetPredicate(
      (w) => w is Text && w.data != null && w.data!.contains(needle));

  testWidgets('non-boss Clock header shows the Hebrew stop title, not English',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();
    final state = ClockState();
    await state.load();

    // A regular (non-boss) morning stop. stopN(he) => "תחנה N".
    final level = ClockMap.trail(TimeWorld.morning).levels.firstWhere(
          (l) => !l.isBoss,
        );

    await pumpClock(tester, level, state: state, profile: profile);

    // The Hebrew "תחנה N" title renders.
    expect(textContaining('תחנה'), findsWidgets);
    // The raw English chrome does not leak into any header Text.
    expect(textContaining('Stop '), findsNothing);
    expect(textContaining('Guardian'), findsNothing);
  });

  testWidgets('guardian Clock header shows the Hebrew guardian name',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();
    final state = ClockState();
    await state.load();

    // The morning boss/guardian stop. ch.guardian.name morning => "תרנגול אדום".
    final level = ClockMap.trail(TimeWorld.morning).levels.firstWhere(
          (l) => l.isBoss,
        );

    await pumpClock(tester, level, state: state, profile: profile);

    // The Hebrew guardian name renders somewhere in the header.
    final hebrewHeader = find.byWidgetPredicate(
        (w) => w is Text && w.data != null && _hebrew.hasMatch(w.data!));
    expect(hebrewHeader, findsWidgets);
    expect(textContaining('תרנגול אדום'), findsWidgets);
    // The English guardian name/label must not leak.
    expect(textContaining('Rooster Red'), findsNothing);
    expect(textContaining('Guardian'), findsNothing);
  });
}
