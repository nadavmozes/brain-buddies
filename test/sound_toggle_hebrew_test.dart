// Verifies the shared SoundToggleButton localizes its label.
//
// In Hebrew mode it reads 'צליל: פועל' / 'צליל: כבוי'; with no L10n ancestor
// it falls back to English ('Sound: On' / 'Sound: Off').

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/core/theme/app_theme.dart';
import 'package:brain_buddies/core/widgets/sound_toggle_button.dart';

void main() {
  Future<void> pumpToggle(
    WidgetTester tester, {
    required bool soundOn,
    required AppLang lang,
    required Listenable notifier,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: L10n(
          lang: lang,
          notifier: notifier,
          child: Scaffold(
            body: SoundToggleButton(soundOn: soundOn, onToggle: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Hebrew sound toggle shows Hebrew on/off labels',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    await pumpToggle(tester,
        soundOn: true, lang: AppLang.he, notifier: profile);
    expect(find.text('צליל: פועל'), findsOneWidget);

    await pumpToggle(tester,
        soundOn: false, lang: AppLang.he, notifier: profile);
    expect(find.text('צליל: כבוי'), findsOneWidget);
  });

  testWidgets('English sound toggle shows English on/off labels',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile();
    await profile.load();

    await pumpToggle(tester,
        soundOn: true, lang: AppLang.en, notifier: profile);
    expect(find.text('Sound: On'), findsOneWidget);

    await pumpToggle(tester,
        soundOn: false, lang: AppLang.en, notifier: profile);
    expect(find.text('Sound: Off'), findsOneWidget);
  });
}
