# Phase 6 — i18n Leak Fix + UI Consistency + Word Wizard Speaker Removal

Implementation plan for `feature/i18n-foundation` worktree. All work happens in
`c:\Users\USER\OneDrive\מסמכים\Math Adventure\.worktrees\i18n-foundation`.
Git: `git -C <worktree>`. Every path below is relative to the worktree root.

Authoritative sources (already applied verbatim below): the leak audit
`.agents/tasks/remaining-strings-audit.md` and the Hebrew strings doc
`c:\Users\USER\OneDrive\מסמכים\Math Adventure\.agents\tasks\hebrew-strings-for-review.md`.

## Build / test / verify (Windows PowerShell)
- Build (real compiler check): `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web`
  — SUCCESS = the line `Built build\web` is present. A trailing Select-String
  `Exit Code: 1` with no matches after the Built line is NOT a failure.
- Test: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` — 89 tests baseline must stay green (plus the new/updated tests).
- Do NOT run `flutter analyze` (crashes on the Hebrew path). Fix imports by hand.
- PowerShell: use `;` not `&&`, `$env:VAR` not `%VAR%`.

## Conventions (reference pattern = Money Math)
- Chrome text → `context.l10n.<key>` (abstract `AppStrings` + `EnStrings` + `HeStrings` in `lib/core/l10n/app_strings.dart`).
- Data text → `context.tr('<domain>', <key>, <englishFallback>)` via `LocalizedCatalog` (`lib/core/l10n/localized_catalog.dart`).
- Service generators with no `BuildContext` take an `AppLang lang` param; the screen resolves `_lang = L10n.read(context).lang` in `initState` (see `MoneyQuestionGenerator.forLevel` / `MoneyGameScreen`).
- Keep numeric islands LTR (math equations, `3:30` clock labels, coin amounts) — wrap in `Directionality(textDirection: TextDirection.ltr, ...)` (already done at those sites; preserve it).
- Every new `AppStrings` key is added in THREE places: the abstract class, `EnStrings` (English = the exact current literal), `HeStrings` (Hebrew from the strings doc, verbatim).
- **Extension-import gotcha:** a display site that newly calls an enum extension getter (`SkillInfo.fromLabel`, `ShapeKindInfo.label`, etc.) MUST import the file that defines the extension, even if the enum type arrived transitively. Flagged inline on each affected item.

---

## GROUP 0 — l10n foundation (new keys + new catalog domain). DO FIRST.

Everything else depends on these keys existing. All three files below are edited
in one pass, then one build.

- [ ] 0.1 Add every new chrome key to `AppStrings` (abstract) + `EnStrings` + `HeStrings`.
      File: `lib/core/l10n/app_strings.dart`
      New keys (En literal → He from strings doc):
      - `soundOn` → `'Sound: On'` / `'צליל: פועל'`
      - `soundOff` → `'Sound: Off'` / `'צליל: כבוי'`
      - `buddyGrew` → `'🎉 Buddy grew!'` / `'🎉 החבר גדל!'`
      - `nqHeroLevel` → `'Hero Level'` / `'דרגת גיבור'`
      - `nqTotalStars` → `'Total Stars'` / `'סך הכוכבים'`
      - `nqDayStreakLabel` → `'Day Streak'` / `'רצף ימים'`
      - `nqSkills` → `'Skills'` / `'מיומנויות'`
      - `nqGrownupTip` → `'Tip for grown-ups'` / `'טיפ למבוגרים'`
      - `nqTipDefault` → `'Keep playing a few quests so we can spot which skills need the most practice.'` / `'שחקו עוד כמה סבבים כדי שנוכל לזהות אילו מיומנויות דורשות תרגול.'`
      - `nqTipWeakest(String skill)` → `'Right now $skill could use the most practice. Try a few short sessions focused on that skill.'` / `'כרגע כדאי לתרגל הכי הרבה את $skill. נסו כמה סבבים קצרים שמתמקדים במיומנות הזו.'`
      - `nqNoQuestionsYet` → `'No questions yet'` / `'עדיין אין שאלות'`
      - `resetConfirmTitle` → `'Reset all progress?'` / `'לאפס את כל ההתקדמות?'`
      - `resetConfirmBody` → `'This erases stars, XP, coins, avatars and awards across all games. This cannot be undone.'` / `'פעולה זו תמחק כוכבים, נקודות ניסיון, מטבעות, דמויות ופרסים בכל המשחקים. אי אפשר לבטל.'`
      - `cancel` → `'Cancel'` / `'ביטול'`
      - `reset` → `'Reset'` / `'איפוס'`
      - `masteryJustStarting` → `'Just starting'` / `'רק מתחילים'`
      - `masteryNeedsPractice` → `'Needs practice'` / `'צריך תרגול'`
      - `masteryPracticing` → `'Practicing'` / `'מתרגלים'`
      - `masteryStrong` → `'Strong'` / `'חזק'`
      - `masteryMastered` → `'Mastered'` / `'שולט'`
      - Clock: `clockPromptRead` → `'What time is it?'` / `'מה השעה?'`
      - `clockPromptFind(String spoken)` → `'Which clock shows $spoken?'` / `'איזה שעון מראה $spoken?'`
      - `clockPromptSet(String spoken)` → `'Set the clock to $spoken'` / `'כוונו את השעון ל-$spoken'`
      - `clockPromptElapsed(String spoken, String hours)` → `"It's $spoken. What time in $hours?"` / `'השעה $spoken. מה תהיה השעה בעוד $hours?'`
      - `clockHours(int n)` → En: `n == 1 ? '1 hour' : '$n hours'`; He: `n == 1 ? 'שעה' : '$n שעות'`
      - `clockHour` → `'Hour'` / `'שעה'`
      - `clockMinute` → `'Minute'` / `'דקה'`
      - `clockSpoken(int hour, int minute)` — language-aware spoken-time formatter (replaces `ClockTime.spoken` at the display/generator layer). English must reproduce the current `ClockTime.spoken` output exactly:
        - minute 0 → En `"$hour o'clock"`, He `'השעה $hour'`
        - minute 30 → En `'half past $hour'`, He `'$hour וחצי'`
        - minute 15 → En `'quarter past $hour'`, He `'$hour ורבע'`
        - minute 45 → En `'quarter to ${hour == 12 ? 1 : hour + 1}'`, He `'רבע ל-${hour == 12 ? 1 : hour + 1}'`
        - otherwise → `'$hour:${minute.toString().padLeft(2, '0')}'` (both languages, numeric LTR)
      - Shape: `ssPromptIdentify` → `'What shape is this?'` / `'איזו צורה זו?'`
      - `ssPromptFind(String shapeName)` → `'Which one is a $shapeName?'` / `'איזו היא $shapeName?'`
      - `ssPromptSides` → `'How many sides does this shape have?'` / `'כמה צלעות יש לצורה הזו?'`
      - `ssPromptPattern` → `'What comes next?'` / `'מה בא אחר כך?'`
      - Game two-line logos (one key per line, per game — see Group F/E). Add:
        `nqLogoLine1`/`nqLogoLine2`, `ssLogoLine1`/`ssLogoLine2`, `wwLogoLine1`/`wwLogoLine2`,
        `chLogoLine1`/`chLogoLine2`, `mmLogoLine1`/`mmLogoLine2`, `memLogoLine1`/`memLogoLine2`.
        En = current literals (`'NUMBER'`/`'QUEST'`, `'SHAPE'`/`'SAFARI'`, `'WORD'`/`'WIZARD'`,
        `'CLOCK'`/`'HERO'`, `'MONEY'`/`'MATH'`, `'MEMORY'`/`'MATCH'`).
        He (2 lines) = `'מסע'`/`'המספרים'`, `'ספארי'`/`'הצורות'`, `'קוסם'`/`'המילים'`,
        `'גיבור'`/`'השעון'`, `'חשבון'`/`'הכסף'`, `'משחק'`/`'הזיכרון'`.
      Verify: build web — `app_strings.dart` compiles (the abstract class and both impls match).

- [ ] 0.2 Add the `ss.shape.label` data domain to `LocalizedCatalog._he`.
      File: `lib/core/l10n/localized_catalog.dart`
      Add a new domain map keyed by `ShapeKind.name`:
      `'ss.shape.label': { 'circle':'עיגול', 'oval':'אליפסה', 'triangle':'משולש', 'square':'ריבוע', 'rectangle':'מלבן', 'pentagon':'מחומש', 'hexagon':'משושה', 'star':'כוכב' }`
      Verify: build web succeeds.

Verify Group 0: `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web` → `Built build\web`. Then `flutter test` (89 pass — no behavior changed yet).

---

## GROUP A — Game-screen HEADER leaks (audit §4, H1–H12)

Fix each DISPLAY site to use the same localized getters the trail screens use.
Do NOT change the model `title`/`name` getters (keep English fallback).

- [ ] A.1 Number Quest header + skill tag (H1, H2, H3). File: `lib/games/number_quest/screens/game_screen.dart`
      - `_headerTitle` (≈ lines 232–246): remove the `isCampaign` gate. For a boss, always `'${level.boss.emoji} ${context.tr('nq.boss.name', level.bossId, level.boss.name)}'`. For a non-boss, always `context.l10n.levelN(level.number)` (the `bossUpper` case is already covered because bosses go through the boss branch). Keep the `widget.isDaily` → `nqDailyHeader` branch unchanged.
      - `_QuestionCard` (H3, ≈ line 487): always pass a localized `labelOverride`. In `build`, change the `_QuestionCard(labelOverride: widget.level.mult != null ? ... : null)` call to always compute `context.tr('nq.skill.label', SkillInfo.fromLabel(_problem.operatorLabel).name, _problem.operatorLabel)`. Then uppercase at the display site (`(labelOverride ?? problem.operatorLabel).toUpperCase()` stays). You may drop the now-always-set `labelOverride` nullability, but keeping it set is fine.
      - Extension-import: `SkillInfo` is already imported (`../models/skill.dart`). OK.
      Verify: build web; `flutter test` green.

- [ ] A.2 Shape Safari game header (H4, H5). File: `lib/games/shape_safari/screens/safari_game_screen.dart`
      - Header `title` (≈ lines 170–171): guardian → `'${widget.level.guardian.emoji} ${context.tr('ss.guardian.name', habitat.name, widget.level.guardian.name)}'`; non-guardian → `'${habitat.emoji} ${widget.level.isGuardian ? context.l10n.guardian : context.l10n.stopN(widget.level.number)}'`. (Note `habitat` is `widget.level.habitat`.)
      Verify: build web; test green.

- [ ] A.3 Shape Safari result banner guardian name (H6). File: `lib/games/shape_safari/screens/safari_result_screen.dart`
      - Where `safariFriendBanner(level.guardian.name)` is built (≈ line 165), resolve the name first: `context.tr('ss.guardian.name', level.habitat.name, level.guardian.name)`. Ensure `l10n`/`context.tr` is available in that scope (import `../../../core/l10n/l10n.dart` if not already).
      Verify: build web; test green.

- [ ] A.4 Clock Hero game header (H7, H8). File: `lib/games/clock_hero/screens/clock_game_screen.dart`
      - Header `title` (≈ lines 183–184): guardian → `'${widget.level.guardian.emoji} ${context.tr('ch.guardian.name', world.name, widget.level.guardian.name)}'`; non-guardian → `'${world.emoji} ${widget.level.isBoss ? context.l10n.guardian : context.l10n.stopN(widget.level.number)}'` (ClockLevel uses `isBoss` for guardian — confirm the actual flag name in `time_world.dart`; use `context.l10n.guardian` for the guardian/boss stop and `stopN` otherwise). `world` = `widget.level.world`.
      Verify: build web; test green.

- [ ] A.5 Money Math game header (H9). File: `lib/games/money_math/screens/money_game_screen.dart`
      - Header `title` (≈ lines 153–154): isBoss → `'${widget.level.guardian.emoji} ${context.tr('mm.guardian.name', world.name, widget.level.guardian.name)}'`; else → `'${world.emoji} ${context.l10n.stopN(widget.level.number)}'`. `world` = `widget.level.world` (already in scope).
      Verify: build web; test green.

- [ ] A.6 Memory Match game header (H10). File: `lib/games/memory_match/screens/memory_game_screen.dart`
      - Header `title` (≈ lines 172–173): guardian → `'${guardian.emoji} ${context.tr('mem.guardian.name', world.name, guardian.name)}'`; else → `'${world.emoji} ${context.l10n.stopN(level.number)}'`. Read the file to confirm the exact field/flag names (`isBoss`/`isGuardian`, `world`, `guardian`).
      Verify: build web; test green.

- [ ] A.7 Word Wizard game header (H11, H12). File: `lib/games/word_wizard/screens/wizard_game_screen.dart`
      - Header `title` (≈ lines 164–165): boss → `'${widget.level.boss.emoji} ${context.tr('ww.boss.name', widget.level.chapter.name, widget.level.boss.name)}'`; non-boss → `'${widget.level.chapter.emoji} ${widget.level.isBoss ? context.l10n.spellMaster : context.l10n.lessonN(widget.level.number)}'`.
      (This file is also edited by Group F; both edits are compatible — do them together if the same coder owns this file.)
      Verify: build web; test green.

---

## GROUP B — Clock Hero Hebrew path (audit §5, K1–K8)

Thread `AppLang` into the generator (Money Math pattern) and branch prompts +
spoken-time on language. Uses `clockSpoken`/`clockPrompt*`/`clockHours` from 0.1.

- [ ] B.1 Add `lang` to the Clock generator and branch all prompts. File: `lib/games/clock_hero/services/clock_generator.dart`
      - Add `import '../../../core/l10n/app_lang.dart';` and `import '../../../core/l10n/app_strings.dart';`.
      - Add a `final AppLang lang;` field and `{this.lang = AppLang.en}` to the constructor; resolve `final AppStrings s = stringsFor(lang == AppLang.he);` once per generator (or in each builder).
      - `forLevel(ClockLevel level, {Random? random, AppLang lang = AppLang.en})` → pass `lang` into the generator.
      - Replace the hard-coded prompts:
        - `_readClock`: `prompt: s.clockPromptRead`.
        - `_findClock`: `prompt: s.clockPromptFind(s.clockSpoken(answer.hour, answer.minute))`.
        - `_setClock`: `prompt: s.clockPromptSet(s.clockSpoken(target.hour, target.minute))`.
        - `_elapsed`: `final hourWord = s.clockHours(hours); prompt: s.clockPromptElapsed(s.clockSpoken(start.hour, start.minute), hourWord)`.
      - Keep `promptTime.label` / choices `.label` numeric (LTR) unchanged.
      - `_signature` still uses `q.prompt` — fine (now language-specific, still unique within a round).
      Verify: build web; test green.

- [ ] B.2 Resolve `_lang` in the Clock screen and pass to the generator; localize the setter captions. File: `lib/games/clock_hero/screens/clock_game_screen.dart`
      - Add `late final AppLang _lang;` field; in `initState` set `_lang = L10n.read(context).lang;` BEFORE building questions, then `_questions = ClockQuestionGenerator.forLevel(widget.level, lang: _lang);`.
      - For the `setClock` body, pass localized captions into `ClockSetter`: add `hourLabel: context.l10n.clockHour, minuteLabel: context.l10n.clockMinute`.
      Verify: build web; test green.

- [ ] B.3 Localize the Hour/Minute captions in the setter. File: `lib/games/clock_hero/widgets/clock_setter.dart`
      - Add required `String hourLabel` and `String minuteLabel` params to `ClockSetter`; pass them to the two `_StepGroup`s instead of the literals `'Hour'`/`'Minute'`.
      Verify: build web; test green.

(Note K7: `TimeWorld.label`/`subtitle` are already shown via `ch.world.*` catalog — not touched. `ClockTime.spoken` getter may stay in the model as dormant English fallback; the generator no longer calls it. Leaving it compiles fine.)

---

## GROUP C — Shape Safari Hebrew path (audit §6, S1–S6)

Thread `AppLang` into the shape generator and localize every shape-name display
site via the new `ss.shape.label` domain.

- [ ] C.1 Add `lang` to the Shape generator and branch prompts + shape names. File: `lib/games/shape_safari/services/question_generator.dart`
      - Add `import '../../../core/l10n/app_lang.dart';`, `import '../../../core/l10n/app_strings.dart';`, `import '../../../core/l10n/localized_catalog.dart';`.
      - Add `final AppLang lang;` field + `{this.lang = AppLang.en}`; resolve `final AppStrings s = stringsFor(lang == AppLang.he);`. Add a helper `String _shapeLabel(ShapeKind sh) => LocalizedCatalog.resolve('ss.shape.label', sh.name, sh.label, lang: lang);`.
      - `forLevel(SafariLevel level, {Random? random, AppLang lang = AppLang.en})` → pass `lang` through.
      - Prompts: `_identify` → `prompt: s.ssPromptIdentify`; `_find` → `prompt: s.ssPromptFind(_shapeLabel(answer))`; `_countSides` → `prompt: s.ssPromptSides`; `_pattern` → `prompt: s.ssPromptPattern`.
      - Answer choices in `_identify`: `ShapeChoice.text(_shapeLabel(s))` instead of `s.label`.
      - Extension-import: `ShapeKindInfo` (for `.label`, `.name` via enum) already imported via `shape_kind.dart`. `.name` is the Dart enum member — no extension needed. OK.
      Verify: build web; test green.

- [ ] C.2 Resolve `_lang` in the Safari screen; localize the wrong-answer feedback shape name. File: `lib/games/shape_safari/screens/safari_game_screen.dart`
      - Add `late final AppLang _lang;`; in `initState` set `_lang = L10n.read(context).lang;` then `_questions = ShapeQuestionGenerator.forLevel(widget.level, lang: _lang);`.
      - `_correctAnswerText` (≈ line 106): when the correct choice is a shape, localize via `context.tr('ss.shape.label', c.shape!.name, c.shape!.label)` before `l.safariWrong(label)`; when it is a text choice keep `c.text!`.
      Verify: build web; test green.

---

## GROUP D — Chrome literals (audit §3, C1–C17 + mastery labels)

- [ ] D.1 Sound toggle button localization (C1). File: `lib/core/widgets/sound_toggle_button.dart`
      - The widget has a `BuildContext` in `build`; change `label:` to `soundOn ? context.l10n.soundOn : context.l10n.soundOff`. Add `import '../l10n/l10n.dart';`.
      Verify: build web; test green (the sound-toggle test — see Group H tests — asserts Hebrew).

- [ ] D.2 Pet round moment (C2, C3). File: `lib/core/widgets/pet_round_moment.dart`
      - `'Buddy'` → `context.l10n.buddy`; `'🎉 Buddy grew!'` → `context.l10n.buddyGrew`. These are in a `StatelessWidget.build`; `_grewBanner()` currently takes no context — pass `context` to it (or inline the Text). Remove the `const` on the two Text widgets that now read `context.l10n`. Add `import '../l10n/l10n.dart';`.
      Verify: build web; test green.

- [ ] D.3 Number Quest parent screen (C4–C12). File: `lib/games/number_quest/screens/parent_screen.dart`
      - Add `import '../../../core/l10n/l10n.dart';`.
      - AppBar `'Progress'` → `context.l10n.progress`.
      - Stat labels: `'Hero Level'` → `context.l10n.nqHeroLevel`; `'Total Stars'` → `context.l10n.nqTotalStars`; `'Day Streak'` → `context.l10n.nqDayStreakLabel`.
      - `'Skills'` → `context.l10n.nqSkills`.
      - `'Tip for grown-ups'` → `context.l10n.nqGrownupTip`.
      - `_tip(GameState)` → `_tip(BuildContext context, GameState state)`: default branch → `context.l10n.nqTipDefault`; weakest branch → `context.l10n.nqTipWeakest(context.tr('nq.skill.label', weakest.name, weakest.label).toLowerCase())`. (Use the localized skill name, not `skill.label`.) Update the call site to pass `context`.
      - `_SkillRow`: `skill.label` → `context.tr('nq.skill.label', skill.name, skill.label)`; `'No questions yet'` → `context.l10n.nqNoQuestionsYet`; `'${stat.correct} / ${stat.attempts} correct'` → `context.l10n.correctOfTotal(stat.correct, stat.attempts)`; `stat.masteryLabel` → localized mastery (see D.5). `_SkillRow` is a `StatelessWidget` with `context` in build — OK.
      - Extension-import: `SkillInfo` (`.label`, `.name`) is `../models/skill.dart` — already imported. OK.
      Verify: build web; test green.

- [ ] D.4 Number Quest settings screen (C13–C17). File: `lib/games/number_quest/screens/settings_screen.dart`
      - Stat line (≈ lines 112–114): keep digits/emoji, localize words — compose `'⭐ ${state.totalStars} ${context.l10n.stars}   🪙 ${profile.coins} ${context.l10n.coins}   ${context.l10n.levelAbbrev(state.level)}'`. (Reuses existing `stars`/`coins`/`levelAbbrev`.)
      - Reset dialog: `'Reset all progress?'` → `context.l10n.resetConfirmTitle`; body → `context.l10n.resetConfirmBody`; `'Cancel'` → `context.l10n.cancel`; `'Reset'` → `context.l10n.reset`. The dialog uses `dialogContext`; read `context.l10n` from the OUTER context (capture `final l = context.l10n;` before `showDialog`) so the strings resolve against the live `L10n`. Remove `const` where the Text now reads a runtime string.
      Verify: build web; test green.

- [ ] D.5 Localized mastery label (C skill mastery). File: `lib/games/number_quest/screens/parent_screen.dart` (helper) — do NOT change `skill.dart`'s `masteryLabel` (keep as English fallback / for any non-UI use).
      - Add a private helper in `parent_screen.dart`: `String _mastery(BuildContext context, SkillStat stat)` that mirrors `SkillStat.masteryLabel`'s thresholds and returns `context.l10n.masteryJustStarting / masteryMastered / masteryStrong / masteryPracticing / masteryNeedsPractice`. Use it in `_SkillRow` instead of `stat.masteryLabel`.
      Verify: build web; test green.

---

## GROUP E/F — Game two-line logos + Word Wizard speaker removal

### E. Localized two-line logos (audit §10.1 — user confirmed Hebrew logos)
Keys authored in 0.1. In each `_TitleBanner`, replace the two hard-coded line
literals with the localized keys; keep the stylized 2-line comic styling in both
languages. These `_TitleBanner`s are `const` with `const` children — remove
`const` so they can read `context.l10n`.

- [ ] E.1 Number Quest logo. File: `lib/games/number_quest/screens/number_quest_home_screen.dart` (≈ lines 219, 230) → `context.l10n.nqLogoLine1` / `nqLogoLine2`.
- [ ] E.2 Shape Safari logo. File: `lib/games/shape_safari/screens/shape_safari_home_screen.dart` (≈ 182, 191) → `ssLogoLine1`/`ssLogoLine2`.
- [ ] E.3 Word Wizard logo. File: `lib/games/word_wizard/screens/word_wizard_home_screen.dart` (≈ 181, 190) → `wwLogoLine1`/`wwLogoLine2`.
- [ ] E.4 Clock Hero logo. File: `lib/games/clock_hero/screens/clock_hero_home_screen.dart` (≈ 180, 192) → `chLogoLine1`/`chLogoLine2`.
- [ ] E.5 Money Math logo. File: `lib/games/money_math/screens/money_math_home_screen.dart` (≈ 225, 234) → `mmLogoLine1`/`mmLogoLine2`.
- [ ] E.6 Memory Match logo. File: `lib/games/memory_match/screens/memory_match_home_screen.dart` (≈ 180, 189) → `memLogoLine1`/`memLogoLine2`.
      For each: make `_TitleBanner` non-const, add `import '../../../core/l10n/l10n.dart';` if missing, read the two keys in `build`. Keep font sizes, colors, rotation, shadows exactly as-is.
      Verify (all E): build web; test green.

### F. Remove the Word Wizard speaker (user request)
File: `lib/games/word_wizard/screens/wizard_game_screen.dart`
Confirmed sole user of `_q.spokenWord` and `FeedbackService.speak` in the worktree.

- [ ] F.1 Remove the speaker UI + logic.
      - Delete the `_SpeakerButton(...)` render site (≈ lines 205–209) and the surrounding `const SizedBox(height: 10)` that only spaced it (keep the flashcard layout balanced — read the panel and remove only the speaker + its adjacent spacer).
      - Delete the `_SpeakerButton` widget class (≈ lines 255–285).
      - Delete `_speakWord()` (≈ lines 70–85) and the now-unused `_lang`-for-speech comment. `_lang` is STILL needed for question generation (`WordQuestionGenerator.forLevel(..., lang: _lang)`), so KEEP the `_lang` field and its `initState` assignment.
      Verify: build web; test green (after F.3).

- [ ] F.2 Remove the now-unused `spokenWord` getter. File: `lib/games/word_wizard/models/word_question.dart`
      - Delete the `spokenWord` getter (≈ lines 46–50). It is used nowhere else (verified). Do NOT touch `FeedbackService.speak` / `SoundBridge.speak` / `maSpeak` — leave that infrastructure dormant.
      Verify: build web.

- [ ] F.3 Update the broken speaker test. File: `test/word_wizard_speaker_test.dart`
      - The first test (`'Word Wizard shows a speaker button...'`) asserts the speaker icon exists — DELETE this test entirely.
      - The second test (`'Hebrew Word Wizard shows a Hebrew word + English line...'`) is valuable: KEEP it but remove the three speaker lines at its end (the `find.byIcon(Icons.volume_up_rounded)` lookup, the `expect(... findsOneWidget)`, and the `tester.tap(speaker)`); keep the Hebrew-word + English-line assertions and the final `expect(tester.takeException(), isNull)`.
      - Rename the file to `test/word_wizard_hebrew_test.dart` (and update the top-of-file comment) so the name no longer implies a speaker. `git -C <worktree> mv test/word_wizard_speaker_test.dart test/word_wizard_hebrew_test.dart`.
      Verify: `flutter test test/word_wizard_hebrew_test.dart` passes; full `flutter test` green.

---

## GROUP G — Shared StatChip for the streak 🔥 chip (audit §8A)

Extract one reusable chip matching `CoinPill`'s container and render the two
bespoke 🔥 containers through it. No behavior change.

- [ ] G.1 Create `StatChip` in core/widgets. File: `lib/core/widgets/stat_chip.dart`
      - A small comic pill matching `CoinPill`: `Container` with `color: Colors.white`, `Border.all(color: AppTheme.ink, width: 2.5)`, `borderRadius: BorderRadius.circular(14)`, `boxShadow: AppTheme.comicShadow(offset: 3)`, `padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)`; a `Row(mainAxisSize: MainAxisSize.min)` of an emoji/icon `Text(leading, fontSize)` + `SizedBox(width: 6)` + `Text('$value', fontWeight w900)`. API: `StatChip({required String leading, required String value, double fontSize = 18})`.
      Verify: build web.

- [ ] G.2 Replace the hub bespoke 🔥 container. File: `lib/app/game_hub_screen.dart` (`_ProfileBar`, ≈ lines 465–490)
      - Replace the `if (profile.dailyStreak > 0) ...[ Container(...) ]` streak chip with `if (profile.dailyStreak > 0) ...[ StatChip(leading: '🔥', value: '${profile.dailyStreak}', fontSize: 15), const SizedBox(width: 8) ]`. Keep the `CoinPill(amount: profile.coins)` after it. Add `import '../core/widgets/stat_chip.dart';`.
      Verify: build web; test green.

- [ ] G.3 Replace the NQ bespoke 🔥 container. File: `lib/games/number_quest/screens/number_quest_home_screen.dart` (`_Hud`, ≈ lines 180–197)
      - Replace the bespoke streak `Container(...)` with `StatChip(leading: '🔥', value: '${profile.dailyStreak}')` (keep it after the `Spacer`, before `CoinPill`). Add `import '../../../core/widgets/stat_chip.dart';`.
      (This file is also touched by G.3's sibling H.1 and E.1 — same coder owns it.)
      Verify: build web; test green.

---

## GROUP H — Remove the NQ-only hero XP/level bar from the NQ home (audit §8B, Option 1)

- [ ] H.1 Remove `XpBar` from the NQ home HUD. File: `lib/games/number_quest/screens/number_quest_home_screen.dart` (`_Hud`, ≈ line 175)
      - Delete the `XpBar(level: state.level, progress: state.levelProgress, width: 90)` line and the adjacent `const SizedBox(width: 10)` that spaced it. The `_Hud` then shows `HeroBuddy` + `Spacer` + `StatChip` (streak, from G.3) + `CoinPill`.
      - Remove the now-unused `XpBar` import if nothing else in the file uses it (check first; `grep` for `XpBar` in the file).
      - Keep hero-level DATA/logic in `GameState` intact; hero level stays visible in `parent_screen.dart` (localized in D.3).
      Verify: build web; `flutter test` green. Then spot-confirm (read) the other 5 game homes still render `StarCoinHud` + `SoundToggleButton` so they stay consistent — no code change expected there.

Note (consistency caveat): the 5 secondary homes show `StarCoinHud` (star total + coins) and no avatar/streak; the NQ home shows avatar + streak + coins and no star total. The audit's Option 1 only requires removing the NQ-unique XP/level indicator (done here); fully unifying the HUDs across all 6 homes is out of scope for this phase. Flagged, not changed.

---

## GROUP I — Tests (new + extended). Keep all 89 existing green.

Deterministic: seeded `Random`, and for widget tests pump under
`L10n(lang: AppLang.he, notifier: profile, child: ...)` with a 430×900 surface
(`tester.view.physicalSize = const Size(430, 900)`), following the pattern in the
existing `word_wizard_speaker_test.dart` Hebrew test.

- [ ] I.1 Clock Hero generator Hebrew prompts. File: `test/clock_hero_hebrew_generator_test.dart` (new)
      - `ClockQuestionGenerator.forLevel(level, random: Random(1), lang: AppLang.he)` over several levels; assert each `q.prompt` contains Hebrew (`RegExp(r'[\u0590-\u05FF]')`) and does NOT contain `"o'clock"`/`'What time'`/`'Which clock'`/`'Set the clock'`/`'hours'`. Assert the English path (`lang: AppLang.en`) still produces the original English prompts (byte-identical regression guard).
      Verify: `flutter test test/clock_hero_hebrew_generator_test.dart`.

- [ ] I.2 Shape Safari generator Hebrew prompts + shape names. File: `test/shape_safari_hebrew_generator_test.dart` (new)
      - `ShapeQuestionGenerator.forLevel(level, random: Random(1), lang: AppLang.he)`; assert prompts contain Hebrew and not `'What shape'`/`'Which one'`/`'How many sides'`/`'What comes next'`; assert at least one `identify` question's text choices contain a Hebrew shape name (e.g. `עיגול`/`ריבוע`). Assert English path unchanged.
      Verify: `flutter test test/shape_safari_hebrew_generator_test.dart`.

- [ ] I.3 Game-screen header shows localized title in Hebrew. File: `test/game_header_hebrew_test.dart` (new)
      - Pump a game screen (e.g. Clock Hero or Number Quest, a non-boss level) under `L10n(lang: AppLang.he, ...)` + 430×900. Assert the header Text shows the Hebrew `stopN`/`levelN` or Hebrew guardian name (Hebrew regex match) and NOT the raw English `'Stop N'`/`'Level N'`/`'Guardian'`. Use a boss/guardian level in a second case to assert the Hebrew guardian name from the catalog. Mirror the pump scaffolding from the Word Wizard Hebrew test (SharedPreferences mock, loaded profile+state).
      Verify: `flutter test test/game_header_hebrew_test.dart`.

- [ ] I.4 Sound toggle shows Hebrew. File: `test/sound_toggle_hebrew_test.dart` (new)
      - Pump `SoundToggleButton(soundOn: true, onToggle: () {})` under `L10n(lang: AppLang.he, notifier: ...)`; assert `find.text('צליל: פועל')` (and `soundOn: false` → `'צליל: כבוי'`). Assert English default shows `'Sound: On'`/`'Sound: Off'`.
      Verify: `flutter test test/sound_toggle_hebrew_test.dart`.

- [ ] I.5 Full suite. Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` — all pass (89 baseline, minus the 1 deleted speaker test, plus the kept Hebrew test and I.1–I.4).

---

## Final verification
- `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web` → `Built build\web`.
- `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` → all green.
- Clean up any scratch files. Commit on `feature/i18n-foundation`; do not push.

## Intentionally left English (by design)
- The hidden admin/dev screen (`admin_screen.dart`): `adminTitle` / `resetEverything`
  are English in BOTH languages by design (hidden developer tool, not kid-facing).
  Not changed. The hub "coming soon" snackbar and all other audit §2 items are
  already localized — not touched.
- Model getters (`level.title`, `*.guardian/boss.name`, `ShapeKind.label`,
  `ClockTime.spoken`, `SkillInfo.label`, `SkillStat.masteryLabel`) keep their
  English values as fallbacks; only the DISPLAY sites were changed.
- Numeric islands (math equations, `3:30` clock labels, coin amounts) stay LTR.
