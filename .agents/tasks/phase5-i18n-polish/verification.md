# Phase 5 — i18n polish / loose-ends — Verification

Branch: feature/i18n-foundation (worktree .worktrees/i18n-foundation)

## What was changed

1. **RTL boss-header overflow** — `lib/core/widgets/game_header.dart`: wrapped the
   title `Text` in `Flexible` with `maxLines: 1`, `softWrap: false`,
   `overflow: TextOverflow.ellipsis`. The `Spacer` + `TimerChip` + count label +
   progress bar layout is unchanged, so the row can no longer overflow in LTR or
   RTL at the 430px frame.

2. **Three unlocalized leftovers** routed through `AppStrings` (En byte-identical
   + He added):
   - `'📸 Snap!'` → `AppStrings.safariSnap` (En `'📸 Snap!'`, He `'📸 קליק!'`),
     swapped in `lib/games/shape_safari/screens/safari_game_screen.dart`.
   - `'🎉 LEVEL UP!  You are now Level N'` → `AppStrings.nqLevelUp(level)`
     (En byte-identical, He `'🎉 עליתם רמה!  אתם עכשיו רמה N'`), swapped in
     `lib/games/number_quest/screens/result_screen.dart`.
   - `'📅 Daily'` (the Number Quest daily-challenge header) → `AppStrings.nqDailyHeader`
     (En `'📅 Daily'`, He `'📅 יומי'`), swapped in
     `lib/games/number_quest/screens/game_screen.dart`.
     (The hub Daily action tile was already localized via `context.l10n.daily`.)

3. **10-agora coin chip clarity** — `lib/games/money_math/models/money_question.dart`:
   `agora10.chipLabel` changed from `'10'` to `'10א'` (10 + agora mark) so it never
   reads as ₪10. CoinChip uses FittedBox scaleDown inside CoinChipRow's LayoutBuilder,
   so the slightly longer label shrinks to fit — no overflow. ₪ chips
   (₪1/₪2/₪5/₪10) and agora chips (10א, ½₪) remain clearly distinct.

4. **Refrigerator placeholder (He word #57)** — `lib/games/word_wizard/models/word_bank.dart`:
   replaced `מקרר`/🧊 placeholder with **מזלג (prompt מַזְלֵג) 'fork' 🍴** — a clean,
   kid-recognizable home/food word. Total word count unchanged (one-for-one swap).
   No test hard-codes the old word, so no test change was needed.

## Verification run (in the worktree)

- `flutter build web` → **Built build\web** (success).
- `flutter test` → **All tests passed! (89 tests, +89)**.

No `flutter analyze` (crashes on the non-ASCII path, per steering).
