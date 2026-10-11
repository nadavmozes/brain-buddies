# Implementation Plan — Batch 4: P1 content + tests + widget promotion

Worktree (ALL paths absolute under this root):
`c:\Users\USER\OneDrive\מסמכים\Math Adventure\.worktrees\review-improvements`
Branch: `feature/review-improvements` (do NOT branch, merge, or push).

Build/test commands (PowerShell; use `;` not `&&`):
- Build: `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web` — SUCCESS = the line
  `Built build\web` appears. A trailing Select-String `Exit Code: 1` with no matches
  after the Built line is NOT a failure.
- Test: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` — currently 15 tests; all must pass
  and the count only grows as Task 2 adds tests.
- Do NOT run `flutter analyze` (crashes on the Hebrew path).

Ordering rule: do Task 2 (tests) FIRST so current behavior is locked before Task 3 touches
widgets. Task 1 (content) can come before or after Task 2 but MUST precede the Task-2 word
generator tests only if those tests assert on specific new words — they do not (they assert
structural properties), so Task 1 and Task 2 are independent. Re-run build web + test after each
logical chunk and commit in chunks.

Key facts discovered during exploration (ground truth for the implementer):
- `WordQuestionGenerator.forLevel`, `ShapeQuestionGenerator.forLevel`,
  `ClockQuestionGenerator.forLevel`, `MoneyQuestionGenerator.forLevel`, and
  `ProblemGenerator.forLevel` all accept a named `Random? random` — use `Random(seed)` for
  determinism.
- Choice shapes differ by question type and are NOT always a 4-text-choice list:
  - Word Wizard `WordQuestion.choices` is always a 4-item `List<String>` (word, letter, or
    spelling options). `correctIndex` indexes it.
  - Shape Safari `ShapeQuestion.choices` is a 4-item `List<ShapeChoice>` (shape OR text).
  - Clock `ClockQuestion`: `readClock`/`elapsed` use `textChoices` (4), `findClock` uses
    `clockChoices` (4), `setClock` has NO choice list (correctness checked vs `targetTime`,
    `correctIndex` is a dummy 0). The "4 distinct choices" assertion must SKIP `setClock`.
  - Money `MoneyQuestion`: `countCoins`/`makeChange` use `textChoices` (4), `makeAmount` uses
    `pileChoices` (4), `whichMore` uses `pileA`/`pileB` (exactly 2 options, correctIndex 0/1).
    The "4 distinct choices" assertion must be type-aware (whichMore = 2 piles distinct totals).
  - Number Quest `MathProblem.choices` is a 4-item `List<int>` including `answer`.
- Level maps + ordered-id accessors: `WizardMap.allLevels`, `SafariMap.allLevels`,
  `ClockMap.allLevels`, `MoneyMap.allLevels`, `WorldMap.allLevels` (Number Quest). Each level has
  `.id`, `.questionCount`, `.isBoss`/`.isGuardian`.
- Stars thresholds (shared in `GameProgressStore.starsForPercent` and duplicated in
  `GameState.completeLevel`): >=90 -> 3, >=70 -> 2, >=50 -> 1, else 0.
- `isLevelUnlockedById` (GameProgressStore) and `GameState.isLevelUnlocked` (NQ): first level
  unlocked; otherwise previous level in order needs >=1 star.
- Five sibling stores extend `GameProgressStore`: SafariState, WizardState, ClockState,
  MoneyState, MemoryState. Number Quest's `GameState` is standalone (nq_ keys, XP).
- Mission rollover: `PlayerProfile._rolloverMissionsIfNeeded()` is private; it is exercised
  indirectly via `reportMission`/`claimMission` (both call it first). Seed a stale
  `profile_mission_day` via `SharedPreferences.setMockInitialValues` as in
  `test/mission_rollover_test.dart`.
- Memory Match has NO question generator (deck-based) — skip it in generator tests.
- Secondary home screens (shape_safari, word_wizard, clock_hero, memory_match, money_math) share
  a near-identical top Row (back link + star/coin HUD) and an inline sound-toggle ComicButton.
  Number Quest's home uses a different layout (`Align`-wrapped back link + a private `_Hud`),
  so leave NQ OUT of the HUD/back-link/sound-toggle promotions.
- Game screens (shape_safari, word_wizard, clock_hero, money_math) share a header Row (title +
  `TimerChip(seconds: _elapsed)` + `'n / total'` + a `ClipRRect`+`LinearProgressIndicator`).
  Memory Match's header uses `'$_matchedPairs / pairs'` (same shape, different label). Number
  Quest's game screen header is richer (score, right-aligned TimerChip) — leave NQ as-is.
- StarRow size drift on trail/map screens: safari/wizard/clock/memory/money use `size: 17`,
  Number Quest's level map uses `size: 18`. Result screens use `size: 44` (NQ 46). Align the
  trail drift to a single value (17 -> keep 17 everywhere, change NQ 18 -> 17) only if trivial;
  do NOT touch the result-screen sizes.
- Result reward rows/banners differ: NQ uses private helpers `_rewardRow`, `_recordBanner`,
  `_levelUpBanner` (plus an XP row); safari/wizard/clock/money/memory use inline `Row`s and a
  private `_banner`. The banner box styling (NQ `_recordBanner` vs others' `_banner`) is NOT
  guaranteed pixel-identical — treat reward-row + banner promotion as the riskiest item.

---

## Task 2 — High-value unit tests (DO FIRST)

- [ ] 1. Add PlayerProfile daily-streak tests.
      New file `test/player_profile_streak_test.dart`. Use
      `SharedPreferences.setMockInitialValues({...})` to seed `profile_last_day` /
      `profile_daily_streak`, then `PlayerProfile()..load()` and call `recordPlayDay()`. Cover:
      (a) same-day second call is a no-op (streak unchanged, returns same value); (b) consecutive
      day increments (seed last_day = yesterday, streak = N -> N+1); (c) a gap/missed day resets to
      1 (seed last_day = 3 days ago); (d) a month boundary and a year boundary behave as
      consecutive when the stored day is literally the previous calendar day. Because
      `recordPlayDay` reads `DateTime.now()`, seed `profile_last_day` relative to
      `DateTime.now()` (yesterday = now - 1 day) rather than hard-coding dates; for the
      month/year-boundary cases, assert the yesterday-string logic by seeding
      `now - Duration(days:1)` and asserting increment (the boundary is covered because the
      `_dayKey` subtraction crosses it only when today is the 1st — document that the test
      verifies the "previous calendar day" rule, not a frozen clock).
      Files: `test/player_profile_streak_test.dart`
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test test/player_profile_streak_test.dart` — new tests pass.

- [ ] 2. Add PlayerProfile missions tests.
      New file `test/player_profile_missions_test.dart`. Cover: (a) `Missions.forDay(day)`
      determinism — same `DateTime` yields the same 3 ids across calls, and the list length is 3
      (mirror `mission_rollover_test.dart`); (b) `reportMission` clamps to target (report far more
      than target -> progress == target) and ignores non-matching metrics (report a metric no
      active mission tracks -> no progress change); (c) `claimMission` pays `rewardCoins` exactly
      once and only when complete — claiming an incomplete mission returns 0 and no coins; claiming
      a complete one returns `rewardCoins`, increases `profile.coins` by that amount, and a second
      claim returns 0; (d) midnight rollover — seed `profile_mission_day` = yesterday with stale
      `profile_mission_progress`/`profile_mission_claimed`, then a `reportMission` rolls over
      (stale progress cleared, persisted day == today) exactly as `mission_rollover_test.dart`
      already asserts (extend, do not duplicate — if coverage overlaps, keep the new assertions
      focused on clamp + claim-once semantics). To drive a specific mission for claim tests, read
      `profile.todaysMissions`, pick one, and `reportMission(m.metric, m.target)` to complete it.
      Files: `test/player_profile_missions_test.dart`
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test test/player_profile_missions_test.dart` — new tests pass.

- [ ] 3. Add level-unlock tests across all game maps.
      New file `test/level_unlock_test.dart`. Write ONE parameterized test over the five
      GameProgressStore games: for each `(storeFactory, allLevels)` pair — SafariState/
      `SafariMap.allLevels`, WizardState/`WizardMap.allLevels`, ClockState/`ClockMap.allLevels`,
      MoneyState/`MoneyMap.allLevels`, MemoryState/`MemoryMap.allLevels` — assert: first level is
      unlocked with no stars; level N (N>=1) is locked until level N-1 has >=1 star. Drive by
      seeding `<prefix>_level_<id>` via `setMockInitialValues` for the previous level, OR by
      awarding a star through the store's `completeLevel` if simpler. Add a separate Number Quest
      case using `GameState` + `WorldMap.allLevels` and `isLevelUnlocked(GameLevel)`. Use each
      store's public `isLevelUnlockedById(id)` (sibling stores) / `isLevelUnlocked(level)` (NQ).
      Files: `test/level_unlock_test.dart`
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test test/level_unlock_test.dart` — new tests pass.

- [ ] 4. Add completeLevel scoring tests (stars thresholds, keep-best, fastest-on-3-star).
      New file `test/complete_level_scoring_test.dart`. Using one sibling store (WizardState is
      representative; GameProgressStore helpers are shared) plus a `PlayerProfile`, drive
      `completeLevel` with `correct`/`total` chosen to hit percent boundaries: 49% (just below
      50 -> 0 stars), 50% (-> 1), 69%/70% (-> 1/2), 89%/90% (-> 2/3). Verify keep-best: a worse
      re-run does not lower stars. Verify fastest-time: only recorded on a 3-star run
      (`elapsedSeconds > 0`), and only when it improves (a slower 3-star run does not overwrite);
      a non-3-star run never sets fastest. Pick `total` values that make the boundary percents
      exact (e.g. total=10 for 50/70/90; total=100 or careful fractions for 49/69/89 — document
      the exact correct/total used). Call `SharedPreferences.setMockInitialValues({})` and
      `await profile.load()` / `await state.load()` first.
      Files: `test/complete_level_scoring_test.dart`
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test test/complete_level_scoring_test.dart` — new tests pass.

- [ ] 5. Add generator forLevel structural tests for the five generators.
      New file `test/generators_test.dart`. For number_quest, shape_safari, word_wizard,
      clock_hero, money_math: for a sample of levels across worlds and seeds (`Random(seed)`),
      assert `forLevel(level, random: Random(seed))` returns exactly `level.questionCount`
      questions; each question's choice set is correct per its TYPE (see "Choice shapes" above —
      Word 4 distinct Strings; Shape 4 distinct ShapeChoices; Clock readClock/elapsed/findClock
      4 distinct, SKIP setClock; Money countCoins/makeChange/makeAmount 4 distinct, whichMore
      exactly 2 piles with different totals; NQ 4 distinct ints); `correctIndex` is in range and
      points at the correct value (Word: `choices[correctIndex] == q.word` where applicable;
      Shape: the correct choice matches the answer; NQ: `choices[answer position] == answer`);
      and dedupe yields mostly-unique questions within a round (allow a small number of repeats
      given the retry guard — assert distinct signature count >= questionCount - 1, or >= 70% of
      count, to stay non-flaky). Build the per-type choice-count helper so the assertion is
      explicit and readable.
      Files: `test/generators_test.dart`
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test test/generators_test.dart` — new tests pass.

- [ ] 6. Add Number Quest problem_generator math-correctness tests.
      New file `test/number_quest_problems_test.dart`. Sweep seeds and all NQ levels
      (`WorldMap.allLevels`) via `ProblemGenerator.forLevel(level, random: Random(seed))`
      (optionally also directly exercise `generateRound(Difficulty.expert)` to force division).
      Assert: every division question (`operatorLabel == 'Division'`) has a whole-number answer
      that satisfies `dividend / divisor == answer` by parsing the `question`; every subtraction
      answer is `>= 0`; no choice in any problem is negative (`choices.every((c) => c >= 0)`);
      the correct `answer` is present in `choices`. Sweep enough seeds (e.g. 0..60) to reliably
      surface division/subtraction in the expert tier.
      Files: `test/number_quest_problems_test.dart`
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test test/number_quest_problems_test.dart` — new tests pass.

- [ ] 7. Run the full suite and build; fix any REAL bug a test reveals.
      If any Task-2 test fails because of an actual product bug (e.g. a generator can emit a
      negative choice, a duplicate choice, a wrong correctIndex, or a non-whole division), fix the
      SOURCE minimally (never weaken the test) and add a one-line code comment noting the fix.
      Document any such fix in the commit message.
      Files: whichever source file holds the bug (e.g.
      `lib/games/number_quest/services/problem_generator.dart`), plus the failing test.
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` (all tests, old + new, pass) then
      `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web` (shows `Built build\web`).
      Commit this chunk on `feature/review-improvements`.

---

## Task 1 — Expand Word Wizard content

- [ ] 8. Expand `WordBank` to ~60–90 real, age-appropriate words across the three tiers.
      Edit `lib/games/word_wizard/models/word_bank.dart`. Keep the `WordEntry(word, emoji)` shape
      and the `easy`/`medium`/`hard` lists + `forDifficulty`/`allWords` API UNCHANGED so the
      generator keeps working. Grow each tier to roughly 20–30 entries: easy = CVC / grade-1 sight
      words (cat, dog, run, red, big, box, hen, mug, net, pen, ten, van, bed, cup...), medium =
      grade-2 (frog, star, cake, nest, hand, lamp, ship, drum, flag, gift, milk, rain, leaf,
      snow...), hard = grade-3 (apple, tiger, house, robot, bread, dragon, flower, pencil,
      rocket, planet, basket, candle, turtle, rabbit, orange...). RULES: real words only, no
      nonsense/placeholders; every word MUST have a sensible emoji for the `namePicture` type —
      a word with no fitting emoji is either given a fitting emoji or kept OUT of the bank (never a
      blank picture). Keep emojis distinct enough that `_distinctWords` can still fill 4 options.
      Ensure words still work with `missingLetter` (len >= 2) and `correctSpelling`. Do NOT change
      `WordQuestion` or the generator in this step. The Batch-2 TTS `spokenWord` continues to work
      because it derives from `word`/correct choice — no code change needed, but confirm new words
      are plain lowercase letters (no spaces/punctuation) so speech reads them correctly.
      OPTIONAL (only if it fits `WordQuestion` with zero churn): a rhyme/first-sound 4th type — if
      it would require new model fields or generator restructuring, DO NOT add it; instead add a
      short `// Future work:` comment in `word_generator.dart` describing it. The word-count
      expansion is the required deliverable.
      Files: `lib/games/word_wizard/models/word_bank.dart` (+ optional comment in
      `lib/games/word_wizard/services/word_generator.dart`)
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web` (shows `Built build\web`) then
      `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` (all pass, including the generator tests
      from Task 2 which now exercise the larger bank). Commit this chunk.

---

## Task 3 — Promote duplicated chrome to core/widgets (promote one, swap, build+test, repeat)

For EACH widget below: create the core widget preserving pixel-identical styling (sizes,
paddings, colors, shadows, font weights), swap every call site, then run build web + test before
moving to the next widget. Game->core import depth is `../../../core/...`. Extension methods need
their defining file imported. Use `const` constructors where the originals do.

- [ ] 9. Promote the home HUD row (star icon + count + CoinPill) as `StarCoinHud`.
      New file `lib/core/widgets/star_coin_hud.dart`. Signature: `StarCoinHud({required int stars,
      required int coins})` rendering exactly `Row(children: [Icon(Icons.star_rounded,
      color: AppTheme.accent, size: 22), Text(' $stars '), SizedBox(width: 8),
      CoinPill(amount: coins)])` with the same text style (`fontSize: 16, FontWeight.w900`). Swap
      the top-right HUD Row in the five secondary homes
      (`shape_safari_home_screen.dart`, `word_wizard_home_screen.dart`,
      `clock_hero_home_screen.dart`, `memory_match_home_screen.dart`,
      `money_math_home_screen.dart`). Keep the surrounding `AnimatedBuilder(animation:
      Listenable.merge([state, profile]))` so it still rebuilds. Do NOT touch Number Quest's
      `_Hud`.
      Files: `lib/core/widgets/star_coin_hud.dart` + the 5 secondary home screens.
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web` (`Built build\web`) then
      `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` (all pass; the existing widget_test opens
      each home and asserts banners/labels). Commit.

- [ ] 10. Promote the 'All Games' back link as `AllGamesBackButton`.
      New file `lib/core/widgets/all_games_back_button.dart`. Render the exact
      `GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: Row(mainAxisSize:
      MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
      Text('All Games', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink))]))`.
      Swap it in the five secondary homes. Keep the text literally 'All Games' (the widget_test
      taps `find.text('All Games')`). Do NOT touch Number Quest (its back link is `Align`-wrapped
      with extra padding — leave as-is, or note as future work).
      Files: `lib/core/widgets/all_games_back_button.dart` + the 5 secondary home screens.
      Verify: build web (`Built build\web`) then test (all pass; widget_test taps 'All Games').
      Commit.

- [ ] 11. Promote the inline sound-toggle ComicButton as `SoundToggleButton`.
      New file `lib/core/widgets/sound_toggle_button.dart`. Signature: `SoundToggleButton({required
      bool soundOn, required VoidCallback onToggle})` rendering the exact ComicButton
      (`label: soundOn ? 'Sound: On' : 'Sound: Off'`, matching icon volume_up/volume_off,
      `color: Colors.white, textColor: AppTheme.ink, fontSize: 16`). Swap in the five secondary
      homes, preserving the `AnimatedBuilder(animation: profile)` wrapper and the existing onToggle
      body that flips BOTH `profile.setSoundOn(v)` and `state.setSoundOn(v)` (keep SoundBridge in
      sync). Do NOT change NQ (its sound setting lives in a settings screen).
      Files: `lib/core/widgets/sound_toggle_button.dart` + the 5 secondary home screens.
      Verify: build web (`Built build\web`) then test (all pass). Commit.

- [ ] 12. Promote the game-screen header (title + TimerChip + 'n / total' + progress bar) as
      `GameHeader`. New file `lib/core/widgets/game_header.dart`. Signature:
      `GameHeader({required Widget title OR required String title, required int elapsedSeconds,
      required int current, required int total, required double progress, Color progressColor})`
      — pick the shape that lets each caller pass its own title text and progress color while
      keeping the Row + 8px gap + `ClipRRect(borderRadius: 10)` + `LinearProgressIndicator(
      minHeight: 12, backgroundColor: Colors.white)` pixel-identical. Swap in the four game
      screens (`safari_game_screen.dart`, `wizard_game_screen.dart`, `clock_game_screen.dart`,
      `money_game_screen.dart`). Memory Match uses a `'$_matchedPairs / pairs'` label with the
      same structure — adapt it too IF the header signature supports a custom count label without
      regressing; otherwise leave Memory Match and note it. Do NOT touch Number Quest's richer
      header.
      Files: `lib/core/widgets/game_header.dart` + the 4 (optionally 5) game screens.
      Verify: build web (`Built build\web`) then test (all pass; the speaker widget_test pumps the
      wizard game screen and finds the volume icon — ensure the header still renders it). Commit.

- [ ] 13. Align the trail-map StarRow size drift.
      In `lib/games/number_quest/screens/level_map_screen.dart` change the trail-map
      `StarRow(earned: stars, size: 18)` to `size: 17` to match safari/wizard/clock/memory/money.
      This is a 1-line change; do NOT touch result-screen star sizes (44/46).
      Files: `lib/games/number_quest/screens/level_map_screen.dart`
      Verify: build web (`Built build\web`) then test (all pass). Commit.

- [ ] 14. Promote result reward rows + banners (RISKIEST — verify pixel parity carefully).
      Create `lib/core/widgets/reward_row.dart` (a `RewardRow({required String emojiOrIcon,
      required String label, required String value})` matching the inline
      `Row(🪙 + 'Coins earned' + Spacer + '+N')` with `fontSize: 17/w700` label and `fontSize:
      20/w900` value) and `lib/core/widgets/result_banner.dart` (a `ResultBanner({required String
      text})` matching the shared `_banner` box: full width, `padding: vertical 10 horizontal 8`,
      `color: AppTheme.primary`, `borderRadius: 12`, `Border.all(AppTheme.ink, width: 2.5)`,
      white `fontSize: 15/w900` centered text). Swap into the near-identical sites in
      safari/word_wizard/clock/money/memory result screens ONLY. Number Quest's `_rewardRow`,
      `_recordBanner`, and `_levelUpBanner` differ (XP row, different banner box) — leave NQ as-is
      and add a `// Future work:` note rather than forcing a risky unification. If any swapped
      banner is not byte-identical to the original `_banner` box in a given screen, DO NOT swap
      that one; keep it inline and note it. The icon-vs-emoji variants (🪙 emoji vs
      Icons.timer_outlined) mean RewardRow should accept a leading `Widget`; keep the 'Your time'
      row inline (it ends in a TimerChip, not a text value) unless a clean generalization exists.
      Files: `lib/core/widgets/reward_row.dart`, `lib/core/widgets/result_banner.dart`, and the
      5 secondary result screens (only the safe sites).
      Verify: build web (`Built build\web`) then test (all pass). Commit. In the commit message,
      list which sites were promoted and which were left inline as future work.

- [ ] 15. Add/extend a widget test for the new core widgets on a phone surface.
      Extend `test/widget_test.dart` (or add `test/core_widgets_test.dart`) to pump a secondary
      home (e.g. Word Wizard) and a game screen on a phone surface
      (`tester.view.physicalSize = const Size(430, 1000)`), asserting the promoted widgets render:
      `find.byType(StarCoinHud)`, `find.byType(AllGamesBackButton)`,
      `find.byType(SoundToggleButton)`, `find.byType(GameHeader)` each `findsWidgets`/
      `findsOneWidget`, and that tapping the sound toggle does not throw and flips the label. Reset
      the surface in `addTearDown`.
      Files: `test/widget_test.dart` or `test/core_widgets_test.dart`
      Verify: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` (all pass) then
      `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web` (`Built build\web`). Final commit of
      the batch on `feature/review-improvements`.

---

## Done criteria for the batch
- `flutter build web` prints `Built build\web`.
- `flutter test` passes (15 original tests + all new Task-2/Task-3 tests).
- Word Wizard bank holds ~60–90 real words, all with sensible emojis, all three question types
  still work, TTS speaks new words.
- The listed chrome widgets live in `lib/core/widgets/` and every safe call site uses them with
  zero visual/behavior change; risky unifications are noted as future work rather than forced.
- No merge, no push. Commits are chunked on `feature/review-improvements`.
