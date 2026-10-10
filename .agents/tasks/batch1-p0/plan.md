# Implementation Plan — Batch 1: P0 Correctness

All work happens in the worktree at
`c:\Users\USER\OneDrive\מסמכים\Math Adventure\.worktrees\review-improvements`.
Paths below are relative to that worktree root. The path contains Hebrew
characters — that is expected. Do NOT run `flutter analyze` (it crashes on the
non-ASCII path); verify with `flutter build web` + `flutter test`.

Build/test commands (PowerShell, `;` not `&&`):

```powershell
& "$env:USERPROFILE\flutter\bin\flutter.bat" build web
& "$env:USERPROFILE\flutter\bin\flutter.bat" test
```

A trailing `Exit Code: 1` from `Select-String` filtering is NOT a build failure —
confirm success by the presence of `Built build\web`.

## Design decisions (made here, grounded in the code)

- **Analytics seam (task 3): inject an optional sink into `PlayerProfile`.**
  `PlayerProfile.onRoundFinished(...)` and `recordGamePlayed(...)` are the single
  hub-wide hooks every game already calls (confirmed: NQ `game_state.dart` and
  `money_state.dart` call `profile.onRoundFinished`; the hub calls
  `recordGamePlayed` in each `_open*`). Giving `PlayerProfile` an optional
  `AnalyticsSink?` field (set once at the hub) and forwarding to it from those two
  methods is the least-invasive, fully decoupled seam: games need ZERO changes,
  and the sink is swappable behind an interface later. Chosen over "hub calls
  analytics after onRoundFinished" because the round-end call lives in each game's
  state, not the hub, so the hub cannot cleanly intercept it.
- **Feedback cue (task 2): one shared widget `AnswerBadge`.** Six screens share
  the same green/red answered-tile pattern, but tiles come in two shapes:
  `ComicButton` text tiles (NQ, money text, clock text, word, shape text) which
  have no overlay slot, and `Container` visual tiles (shape shapes, clock analog,
  money two-piles/pile-choices). A single small `core/widgets/answer_badge.dart`
  returning a positioned check/cross chip, dropped into a `Stack` at each call
  site, avoids six divergent copies while fitting both tile shapes. Recommended
  over editing `ComicButton` (would bloat an unrelated shared widget) and over six
  per-file copies.
- **Make-change gating (task 4): gate by world, not just difficulty.** The
  generator currently picks types purely from the difficulty `d`. Vault's
  `baseDifficulty` is 0.8, so to guarantee the Vault "makes change" promise is met
  AND keep the type out of lower worlds, thread the `MoneyWorld` into generation
  and only offer `makeChange` when `world == MoneyWorld.vault`.

---

## FEAT-001 — Remove Number Quest's duplicate daily streak

- [ ] 1. Delete the duplicate streak implementation from Number Quest state.
      In `lib/games/number_quest/services/game_state.dart` remove: the fields
      `_dailyStreak` and `_lastPlayedDay`; the constants `_kStreak = 'daily_streak'`
      and `_kLastDay = 'last_day'`; the `int get dailyStreak` getter; the private
      method `_updateDailyStreak()`; the `_todayKey()`/`_dayKey()` helpers IF they
      become unused after removal (grep first — they are only used by
      `_updateDailyStreak` here, so remove them too); the `await _updateDailyStreak();`
      call inside `completeLevel`; and the three streak lines in `load()`
      (`_dailyStreak = p.getInt(_kStreak) ?? 0;`, `_lastPlayedDay = p.getString(_kLastDay) ?? '';`)
      and in `reset()` (`_dailyStreak = 0;`, `_lastPlayedDay = '';`,
      `await _prefs?.remove(_kStreak);`, `await _prefs?.remove(_kLastDay);`). The
      shared streak still advances via `profile.onRoundFinished -> recordPlayDay`
      (already called in `completeLevel`).
      Files: `lib/games/number_quest/services/game_state.dart`
      Verify: part of the FEAT-wide build/test below.

- [ ] 2. Repoint the two confirmed call sites to the shared profile streak.
      In `lib/games/number_quest/screens/number_quest_home_screen.dart` (~line 207)
      change `Text('${state.dailyStreak}')` to `Text('${profile.dailyStreak}')`
      (the `_ProfileRow`/header widget already receives `profile`; if the enclosing
      widget does not already hold `profile`, pass it in — confirm by reading the
      widget's constructor). In
      `lib/games/number_quest/screens/parent_screen.dart` (~line 42) the
      `ParentScreen` currently takes only `state`; add a `required PlayerProfile profile`
      field + import `../../../core/services/player_profile.dart`, change
      `_stat('Day Streak', '${state.dailyStreak}')` to use `profile.dailyStreak`,
      and update the one push site that constructs `ParentScreen(...)` to pass
      `profile:` (grep `ParentScreen(` to find it — likely in
      `number_quest_home_screen.dart`; that screen already has `profile`).
      Files: `lib/games/number_quest/screens/number_quest_home_screen.dart`,
      `lib/games/number_quest/screens/parent_screen.dart`, and the file that
      constructs `ParentScreen`.
      Verify: part of the FEAT-wide build/test below.

- [ ] 3. Confirm no dangling references remain.
      Grep the repo for `\.dailyStreak`. Every remaining hit must be
      `profile.dailyStreak` (PlayerProfile's getter — correct to keep). There must
      be NO `state.dailyStreak` left in Number Quest, and no bare `'daily_streak'`
      or `'last_day'` pref keys anywhere in `lib/games/number_quest/`.
      Files: none (verification only).
      Verify: `flutter build web` succeeds (shows `Built build\web`) AND
      `flutter test` passes. Grep `state.dailyStreak` returns nothing in NQ.

## FEAT-004 — Money Math "make change" question type (Vault world)

- [ ] 4. Add the `makeChange` enum case and its fields.
      In `lib/games/money_math/models/money_question.dart` add
      `makeChange` to `MoneyQuestionType` with a doc line (e.g. "You pay X for a
      Y toy; pick the change."). Reuse the existing `textChoices` + `prompt` +
      `correctIndex` fields for rendering (no new fields needed — the answer is a
      cent amount shown as text, same shape as `countCoins`).
      Files: `lib/games/money_math/models/money_question.dart`
      Verify: part of the FEAT-wide build/test below.

- [ ] 5. Generate `makeChange` only in the Vault world.
      In `lib/games/money_math/services/money_generator.dart` thread the world into
      generation: give `forLevel` access to `level.world` and pass it through
      `generateRound`/`generateOne` (add a `MoneyWorld world` param, defaulting to
      a non-vault world so existing callers/tests are unaffected). In `generateOne`,
      add `if (world == MoneyWorld.vault) MoneyQuestionType.makeChange` to the
      `types` list. Implement `_makeChange(d)`: pick a price and a payment amount
      (payment > price), both difficulty-scaled whole-cent amounts (e.g. multiples
      of 5 so the math stays kid-friendly), correct answer = payment − price;
      build 4 DISTINCT non-negative cent choices including the correct one (reuse
      the `_distinctAmounts` helper, which already guarantees distinct positive
      values — guard that the correct change is > 0 by choosing payment ≥ price+5);
      prompt like `'You pay ${_fmt(pay)} for a ${_fmt(price)} toy. How much change?'`.
      Include the new type in `_signature` (it already keys on `type|prompt`, which
      is sufficient since prompt carries the amounts). Keep the ~25-try dedupe loop
      unchanged.
      Files: `lib/games/money_math/services/money_generator.dart`
      Verify: part of the FEAT-wide build/test below.

- [ ] 6. Render `makeChange` in the money game screen.
      In `lib/games/money_math/screens/money_game_screen.dart` `_buildBody()` add a
      `case MoneyQuestionType.makeChange:` that reuses the existing text-choice path
      (`_TextChoices` with the `_q.prompt` already shown above the body). No coin
      pile panel is needed for make-change (the amounts are in the prompt). Confirm
      `_bg(...)` and the `_TextChoices` widget handle it unchanged.
      Files: `lib/games/money_math/screens/money_game_screen.dart`
      Verify: part of the FEAT-wide build/test below.

- [ ] 7. Confirm the Vault world actually serves make-change.
      `MoneyQuestionGenerator.forLevel` must pass `MoneyWorld.vault` for Vault
      levels. Add/extend a unit test in `test/` (new file
      `test/money_make_change_test.dart`) that generates several Vault rounds with a
      seeded `Random` and asserts at least one `MoneyQuestion` has
      `type == MoneyQuestionType.makeChange`, that its `correctIndex` points at a
      non-negative value present in `textChoices`, and that a non-Vault world
      (e.g. `MoneyWorld.piggy`) never produces `makeChange`.
      Files: `test/money_make_change_test.dart`
      Verify: `flutter test` passes (new test green); `flutter build web` shows
      `Built build\web`. This is the FEAT-wide verification for FEAT-001 + FEAT-004.

## FEAT-002 — Non-color answer feedback (accessibility)

- [ ] 8. Create the shared `AnswerBadge` widget.
      New file `lib/core/widgets/answer_badge.dart`: a small `StatelessWidget` that,
      given `bool show`, `bool correct`, renders a comic-style circular chip in a
      tile corner — white `Icons.check_rounded` (correct) or `Icons.close_rounded`
      (wrong) on a `AppTheme.success`/`AppTheme.danger` fill with
      `AppTheme.comicBorder` (or a 2–2.5px ink border) and `AppTheme.comicShadow`.
      Provide a `Positioned`-friendly fixed size (~26px). Add a doc comment that it
      is an ADDITIONAL non-color channel layered over the existing color + SFX for
      red/green color-blind kids. Return `const SizedBox.shrink()` when `!show`.
      Files: `lib/core/widgets/answer_badge.dart`
      Verify: part of the FEAT-wide build/test below.

- [ ] 9. Overlay the badge on every answered choice tile across the five games.
      Wrap each answered tile in a `Stack` (clipBehavior `Clip.none`) and add
      `Positioned(top: -6, right: -6, child: AnswerBadge(show: answered && (isCorrect || isSelected), correct: isCorrect))`.
      Import `../../../core/widgets/answer_badge.dart` in each file. Apply to BOTH
      tile shapes per the design note:
      - `lib/games/number_quest/screens/game_screen.dart` — `_ChoiceGrid`
        `ComicButton` tiles (`isCorrect`/`isSelected` already computed there).
      - `lib/games/word_wizard/screens/wizard_game_screen.dart` — `_ChoiceGrid`
        `ComicButton` tiles (use `index == question.correctIndex` /
        `index == selectedIndex`).
      - `lib/games/shape_safari/screens/safari_game_screen.dart` — `_ChoiceGrid`
        BOTH the shape `Container` tiles and the text `ComicButton` tiles.
      - `lib/games/clock_hero/screens/clock_game_screen.dart` — the `_TextChoices`
        `ComicButton` tiles AND the `clockChoices` `Container` tiles.
      - `lib/games/money_math/screens/money_game_screen.dart` — `_TextChoices`
        (covers `countCoins` and the new `makeChange`), `_TwoPiles`, and
        `_PileChoices`.
      Keep the existing green/red fill, text-color flip, and SFX untouched — the
      badge is purely additive. Memory Match has no multiple-choice grid — skip it.
      Files: the five `*game_screen.dart` listed above.
      Verify: `flutter build web` shows `Built build\web` and `flutter test` passes
      (existing widget tests still green — the badge adds Icons, no text changes).

## FEAT-003 — Local-only analytics (no network, no PII)

- [ ] 10. Create the analytics service + sink interface.
      New file `lib/core/services/analytics_service.dart`. Define a small
      `abstract class AnalyticsSink` with the methods the profile will call:
      `void recordGameOpened(String gameId)` and
      `void recordRound({required int correct, required bool threeStars, required bool bossBeaten})`,
      plus `Future<void> updateSnapshots({required int streak, required int petLevel, required int coins})`.
      Implement `AnalyticsService extends ChangeNotifier implements AnalyticsSink`,
      modeled on `PlayerProfile`/`GameState`: `SharedPreferences`, a `load()`,
      namespaced keys all prefixed `analytics_` (e.g. `analytics_opens_<gameId>`,
      `analytics_rounds_total`, `analytics_correct_total`, `analytics_threestar_total`,
      `analytics_boss_total`, `analytics_snap_streak`, `analytics_snap_pet`,
      `analytics_snap_coins`), defensive `getInt(...) ?? 0` reads, aggregate
      COUNTERS only. NO network, NO PII, NO timestamps finer than a day bucket
      (do not store any timestamp this batch). Add a top doc comment stating it is
      LOCAL-ONLY and COPPA-safe (aggregate counters, no identifiers, no network).
      Files: `lib/core/services/analytics_service.dart`
      Verify: part of the FEAT-wide build/test below.

- [ ] 11. Add the decoupled sink seam to PlayerProfile.
      In `lib/core/services/player_profile.dart` add a nullable field
      `AnalyticsSink? _analytics;` and a setter/ctor param
      `void attachAnalytics(AnalyticsSink sink) { _analytics = sink; }` (import
      `analytics_service.dart`). In `recordGamePlayed(...)` call
      `_analytics?.recordGameOpened(gameId);` (fire regardless of the "already
      played" early-return? — call it BEFORE the early return so repeat opens still
      count opens; place it as the first line). In `onRoundFinished(...)` after the
      existing work call
      `_analytics?.recordRound(correct: correct, threeStars: threeStars, bossBeaten: bossBeaten);`
      and `await _analytics?.updateSnapshots(streak: dailyStreak, petLevel: petLevel, coins: coins);`.
      PlayerProfile must NOT depend on the concrete `AnalyticsService`, only the
      `AnalyticsSink` interface — keep it swappable.
      Files: `lib/core/services/player_profile.dart`
      Verify: part of the FEAT-wide build/test below.

- [ ] 12. Wire analytics once at the hub.
      In `lib/app/game_hub_screen.dart` add a
      `final AnalyticsService _analytics = AnalyticsService();`, import it, and in
      `initState` load it alongside the profile, then call
      `_profile.attachAnalytics(_analytics)` once the analytics `load()` completes
      (do it in the existing `_profile.load().then(...)` chain so ordering is
      deterministic; attaching before the first `_open*`/round is sufficient — no
      UI surfacing required this batch).
      Files: `lib/app/game_hub_screen.dart`
      Verify: part of the FEAT-wide build/test below.

- [ ] 13. Add an analytics unit test.
      New file `test/analytics_test.dart`: with
      `SharedPreferences.setMockInitialValues({})`, construct `AnalyticsService`,
      `load()`, drive `recordGameOpened('number_quest')` twice and
      `recordRound(correct: 3, threeStars: true, bossBeaten: false)`, then assert
      the aggregate getters reflect the counts, and that re-loading a fresh
      instance reads the persisted values back (confirms `analytics_`-prefixed
      persistence). Assert NO key without the `analytics_` prefix is written by the
      service.
      Files: `test/analytics_test.dart`
      Verify: `flutter test` passes (new test green) and `flutter build web` shows
      `Built build\web`. This is the FEAT-wide verification for FEAT-002 + FEAT-003.

## Final verification (whole batch)

Run from the worktree root:

```powershell
& "$env:USERPROFILE\flutter\bin\flutter.bat" build web
& "$env:USERPROFILE\flutter\bin\flutter.bat" test
```

Pass criteria: build output contains `Built build\web`; all tests pass; grep
`state.dailyStreak` finds nothing in `lib/games/number_quest/`; a seeded Vault
round yields at least one `makeChange` question; the analytics service writes
only `analytics_`-prefixed keys.
