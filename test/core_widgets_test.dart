// Verifies the shared core chrome widgets promoted in FEAT-003 render on a
// secondary game home and a game screen, with a phone-sized surface.
//
// Covers StarCoinHud, AllGamesBackButton, SoundToggleButton (on the home) and
// GameHeader (on the game screen). Also checks that tapping the sound toggle
// flips its label without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/core/theme/app_theme.dart';
import 'package:brain_buddies/core/widgets/all_games_back_button.dart';
import 'package:brain_buddies/core/widgets/game_header.dart';
import 'package:brain_buddies/core/widgets/sound_toggle_button.dart';
import 'package:brain_buddies/core/widgets/star_coin_hud.dart';
import 'package:brain_buddies/core/widgets/timer_chip.dart';
import 'package:brain_buddies/games/shape_safari/models/safari_level.dart';
import 'package:brain_buddies/games/shape_safari/screens/safari_game_screen.dart';
import 'package:brain_buddies/games/shape_safari/screens/shape_safari_home_screen.dart';
import 'package:brain_buddies/games/shape_safari/services/safari_state.dart';

void main() {
  testWidgets(
      'Secondary home renders the shared HUD, back link and sound toggle',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = PlayerProfile();
    await profile.load();
    final state = SafariState();
    await state.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: ShapeSafariHome(state: state, profile: profile),
      ),
    );
    await tester.pumpAndSettle();

    // The promoted chrome widgets are present.
    expect(find.byType(StarCoinHud), findsOneWidget);
    expect(find.byType(AllGamesBackButton), findsOneWidget);
    expect(find.byType(SoundToggleButton), findsOneWidget);
    expect(find.text('All Games'), findsOneWidget);

    // Sound starts on; tapping the toggle flips the label without throwing.
    expect(find.text('Sound: On'), findsOneWidget);
    await tester.tap(find.byType(SoundToggleButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sound: Off'), findsOneWidget);
  });

  testWidgets('Game screen renders the shared GameHeader',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = PlayerProfile();
    await profile.load();
    final state = SafariState();
    await state.load();

    final level = SafariMap.allLevels.first;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: SafariGameScreen(state: state, profile: profile, level: level),
      ),
    );
    await tester.pump();

    // The shared header is present, including its live timer chip.
    expect(find.byType(GameHeader), findsOneWidget);
    expect(find.byType(TimerChip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
