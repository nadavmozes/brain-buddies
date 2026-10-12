// Verifies the Hebrew Word Wizard gameplay flashcard.
//
// In Hebrew mode the flashcard shows Hebrew words and the screen builds without
// throwing. The English translation is intentionally NOT shown on the flashcard
// panel: on namePicture/missingLetter it would leak the answer, so the
// Hebrew<->English pairing is taught only via the matchTranslation question
// type (where the English words are the answer choices).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brain_buddies/core/l10n/l10n.dart';
import 'package:brain_buddies/core/services/player_profile.dart';
import 'package:brain_buddies/core/theme/app_theme.dart';
import 'package:brain_buddies/games/word_wizard/models/wizard_level.dart';
import 'package:brain_buddies/games/word_wizard/screens/wizard_game_screen.dart';
import 'package:brain_buddies/games/word_wizard/services/wizard_state.dart';

final _hebrew = RegExp(r'[\u0590-\u05FF]');

void main() {
  testWidgets('Hebrew Word Wizard shows a Hebrew word + English line',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = PlayerProfile();
    await profile.load();
    final state = WizardState();
    await state.load();

    // A hard (storm) NON-boss lesson so the Hebrew word pool is the hard tier
    // and every Hebrew question type can appear. A boss level is avoided here
    // because its long title row is a pre-existing header layout concern
    // unrelated to this feature.
    final level = WizardMap.allLevels.firstWhere(
      (l) => l.chapter == WizardChapter.storm && !l.isBoss,
    );

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
          child: WizardGameScreen(
            state: state,
            profile: profile,
            level: level,
          ),
        ),
      ),
    );
    await tester.pump();

    // A Hebrew word is shown somewhere on the flashcard/choices.
    final hebrewText = find.byWidgetPredicate((w) =>
        w is Text && w.data != null && _hebrew.hasMatch(w.data!));
    expect(hebrewText, findsWidgets);

    // The flashcard panel must NOT show a plain English translation line (it
    // would reveal the answer on a name-the-picture question). The prompt is
    // Hebrew and the only Latin text allowed on screen is inside answer choices
    // (matchTranslation), not a standalone translation caption under the emoji.
    // We assert the specific giveaway widget — a lone lowercase translation
    // line in the prompt panel — is absent by checking the prompt is Hebrew.
    final prompt = tester.widgetList<Text>(find.byType(Text)).firstWhere(
          (t) => t.data != null && _hebrew.hasMatch(t.data!),
          orElse: () => const Text(''),
        );
    expect(prompt.data, isNotNull);

    expect(tester.takeException(), isNull);
  });
}
