# Phase 5 i18n polish: header overflow, three leftover strings, agora chip, fork word

Four small, independent polish fixes on `feature/i18n-foundation`, all contained in a single commit (`98bca3e`) that touches exactly 7 code/string files plus the verification note — no scope creep. The header title in the shared `GameHeader` is wrapped so it can no longer overflow the 430px frame in either direction; three English strings that had escaped the i18n pass are now routed through `AppStrings` with byte-identical English and new Hebrew; the ILS 10-agorot chip label is disambiguated from ₪10; and the Hebrew Word Wizard refrigerator placeholder (word #57) is swapped for a clean word. The verification note and commit message both record `flutter build web` → Built and `flutter test` → 89 passed, so per instructions I did not re-run the suites.

Watch for: nothing blocking. One minor cosmetic observation on the agora label glyph (possible), noted below — not a defect.

**Verdict**: APPROVED

## High-level view

The header fix wraps only the title in `Flexible` with `maxLines: 1` + `softWrap: false` + ellipsis, leaving the `Spacer` → `TimerChip` → count label and the progress bar below exactly as they were. Because the title is the only elastic child competing with fixed-width trailing widgets, this is the right place to absorb overflow, and it works symmetrically for LTR and RTL since Flexible is direction-agnostic.

The three string fixes go through the existing `AppStrings` abstract/En/He pattern. English values are byte-identical to the former hard-coded literals (`'📸 Snap!'`, `'🎉 LEVEL UP!  You are now Level $level'` including the double space, `'📅 Daily'`), emoji preserved, and each gets a sensible Hebrew counterpart. Call sites switch to `context.l10n` / the passed `l` instance cleanly.

The agora chip change is a one-character data edit: `agora10.chipLabel` goes from `'10'` to `'10א'`. Legibility and overflow are already handled upstream by `CoinChip`'s `FittedBox(scaleDown)` inside `CoinChipRow`'s `LayoutBuilder`, both of which are LTR islands — so the money game stays an LTR island and no MediaQuery sizing was introduced.

The word swap replaces `מקרר`/🧊 with `מזלג`/🍴 (fork), keeping the plain form, niqqud `promptForm`, and English translation triplet intact. It is a one-for-one replacement, so the list length is unchanged and no test that counts entries needs updating.

<details>
<summary>Issues (1)</summary>

1. **Agora mark glyph choice (cosmetic, possible)** — `'10א'` uses a bare letter א rather than the conventional agora abbreviation `אג׳`. It reads unambiguously as "not shekel" and fits the chip, so this is acceptable; if a more conventional mark is wanted later, `אג׳` is the Israeli norm. No action required for this gate.

</details>

<details>
<summary>Details</summary>

### Byte-identical English, Hebrew present

The abstract `AppStrings` gains `nqDailyHeader`, `nqLevelUp(int level)`, and `safariSnap`, with overrides in `EnStrings` and `HeStrings`:

- `safariSnap` → En `'📸 Snap!'`, He `'📸 קליק!'`
- `nqLevelUp(level)` → En `'🎉 LEVEL UP!  You are now Level $level'` (the two spaces after `!` are preserved), He `'🎉 עליתם רמה!  אתם עכשיו רמה $level'`
- `nqDailyHeader` → En `'📅 Daily'`, He `'📅 יומי'`

The two-space gap in the level-up string is the easiest thing to break in a byte-identical port; it is intact here. The Number Quest level/boss header title path in `game_screen.dart` stays English byte-identical except the Times Tables campaign, which the surrounding comment documents — the design keeps math/clock/money as LTR islands, so this is intended, not a missed string.

### Verification evidence

The verification note at `.agents/tasks/phase5-i18n-polish/verification.md` and the commit message both record `flutter build web` → **Built build\web** and `flutter test` → **89 tests passed**, and note that `flutter analyze` is skipped because it crashes on the non-ASCII worktree path (per repo steering). Per the review instructions these suites were not re-run; the evidence is present, so no rejection on that basis.

</details>

<details>
<summary>File map</summary>

- `lib/core/l10n/app_strings.dart` — adds `nqDailyHeader`, `nqLevelUp(int)`, `safariSnap` to the abstract class plus En (byte-identical) and He overrides.
- `lib/core/widgets/game_header.dart` — title wrapped in `Flexible` + `maxLines:1`/`softWrap:false`/ellipsis; trailing cluster and progress bar unchanged.
- `lib/games/money_math/models/money_question.dart` — `agora10.chipLabel` `'10'` → `'10א'`; comment added.
- `lib/games/number_quest/screens/game_screen.dart` — daily header literal → `context.l10n.nqDailyHeader`.
- `lib/games/number_quest/screens/result_screen.dart` — level-up literal → `context.l10n.nqLevelUp(outcome.newLevel)`.
- `lib/games/shape_safari/screens/safari_game_screen.dart` — snap literal → `l.safariSnap`.
- `lib/games/word_wizard/models/word_bank.dart` — He #57 `מקרר`/🧊 placeholder → `מזלג`/🍴 (fork).
- `.agents/tasks/phase5-i18n-polish/verification.md` — build/test evidence note.

Full diff: `git show 98bca3e` in the `.worktrees/i18n-foundation` worktree.

</details>
