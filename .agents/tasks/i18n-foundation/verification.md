# Phase 1 — Hebrew/English Localization Foundation — Verification

Worktree: `.worktrees/i18n-foundation` (branch `feature/i18n-foundation`).
Iteration: FIRST (no `review.json` present).

## Commands run (and observed)

```powershell
& "$env:USERPROFILE\flutter\bin\flutter.bat" pub get      # OK (flutter_localizations + intl resolved)
& "$env:USERPROFILE\flutter\bin\flutter.bat" build web    # SUCCESS — "Built build\web" printed
& "$env:USERPROFILE\flutter\bin\flutter.bat" test         # SUCCESS — "All tests passed!"
```

- **CONFIRMED** `build web` prints `Built build\web` (the trailing `Exit Code: 1` is only
  `Select-String` finding no error lines after the Built line — not a build failure).
- **CONFIRMED** `flutter test` → **58 passing** (55 baseline + 3 new localization tests), 0 failing.
- `flutter analyze` was NOT run (crashes on the non-ASCII Hebrew path, per steering).

## Test counts

- Baseline: 55 tests across 16 files — all still green (English defaults preserved).
- Added: `test/localization_test.dart` with 3 tests:
  1. persisted `profile_lang=he` renders Hebrew chrome AND `Directionality == rtl`;
  2. default (no key, en_US env) stays English + LTR;
  3. the EN⇄עב toggle switches chrome live and flips to RTL.
- Final: **58 passing**.

## Hebrew font chosen (CONFIRMED resolves; ASSUMED visually correct)

- English keeps **Baloo 2**. Hebrew uses **Fredoka** (friendly/rounded, ships a Hebrew subset).
- `fontFamilyFallback` = **Heebo** → Baloo 2, so mixed EN/HE + emoji degrade gracefully.
- `AppTheme.build(AppLang)` is now locale-aware; the toggle swaps the font live.
- **ASSUMED / needs human visual check:** that Hebrew renders as real glyphs (not tofu) in a
  browser. The google_fonts package fetches the family at runtime; headless tests cannot confirm
  glyph rendering. A `build web` + on-device/browser visual pass is still required.

## Localization engine (in-repo string table, NOT gen-l10n/ARB) — CONFIRMED

- `lib/core/l10n/app_lang.dart` — `enum AppLang { en, he }` with `locale`, `direction`, `isRtl`,
  `fromCode`, `fromLocale` (Hebrew `he`/`iw` → he, else en).
- `lib/core/l10n/app_strings.dart` — abstract `AppStrings` + `EnStrings`/`HeStrings`. English values
  match the previous hard-coded literals EXACTLY (so English-asserting tests stay green).
- `lib/core/l10n/l10n.dart` — `L10n` `InheritedNotifier<Listenable>` over the `PlayerProfile`;
  `context.l10n`, `context.lang`, `context.isRtl`, `context.tr(domain,key,fallback)`.
  Includes a const English `_fallback` so widgets pumped WITHOUT an `L10n` ancestor (existing
  direct-pump tests) degrade to English instead of throwing.
- `lib/core/l10n/localized_catalog.dart` — id→Hebrew lookup for the data catalogs; English is the
  passed-in fallback (no English duplication → no drift risk).

## Language state + ownership refactor — CONFIRMED

- `PlayerProfile`: added `AppLang lang`, additive key `profile_lang`, `setLang()` (persist +
  notify), load auto-detect from platform locale when key absent, `reset()` removes the key.
  `schemaVersion` unchanged (1). No existing key renamed.
- Ownership moved: `PlayerProfile` + `AnalyticsService` now created/loaded in `BrainBuddiesApp`
  (was in `GameHubScreen`); the hub receives them via constructor and still owns the six game
  stores + `_resetEverything`/admin wiring. `MaterialApp` is wrapped in `AnimatedBuilder(profile)`,
  gains `locale`, `supportedLocales [en,he]`, Global{Material,Widgets,Cupertino}Localizations
  delegates, and wraps the tree in `L10n`. The 430px width cap is preserved.
- `pubspec.yaml`: added `flutter_localizations` (SDK) — pulls `intl`. `pub get` OK.

## RTL sites fixed (§5.2) — CONFIRMED compiles

- `core/widgets/all_games_back_button.dart` — localized label; Row mirrors; arrow flips in RTL.
- `app/game_hub_screen.dart` — `_ProfileBar` streak chip margin → `EdgeInsetsDirectional.only(end:)`;
  avatar edit badge + action-button badge → `PositionedDirectional(end:)`; added the EN⇄עב toggle
  pill; hub tagline/footer/action labels/game titles+taglines/PLAY/SOON localized.
- `number_quest/screens/number_quest_home_screen.dart` — "All Games" row now uses the shared
  (RTL-aware) button under `AlignmentDirectional.centerStart`; `_Hud` streak margin → directional.
- All six **home** world-select screens — chevrons flip in RTL (`Transform.flip`), labels/subtitles
  localized.
- All six **trail/map** screens rewritten onto a shared `TrailMapView` whose nodes use
  `AlignmentDirectional` + a direction-aware painter, so the winding path mirrors in RTL with no
  per-game branching.

## LTR islands kept inside RTL — CONFIRMED

- Number Quest game equation (`3 × 4`) wrapped in `Directionality.ltr`.
- Clock Hero digital time choices (`3:30`) wrapped in `Directionality.ltr` (clock face canvas was
  already LTR and is unchanged).
- Money Math amount choices (`30¢`) wrapped in `Directionality.ltr`.

## Trail-map redesign — CONFIRMED compiles

- New `lib/core/widgets/trail_map.dart` (`TrailMapView` + `TrailNodeData`): a polished winding path
  with a dashed comic connector (CustomPaint), circular medallion nodes, clear locked/unlocked/
  completed states with stars, bigger friendly boss/guardian nodes, consistent spacing, sized via
  `LayoutBuilder`/`constraints.maxWidth` (never `MediaQuery.size`). Mirrors in LTR and RTL.
- Adopted by all six games (number_quest, shape_safari, word_wizard, clock_hero, money_math,
  memory_match). Unlock/star behavior is UNCHANGED — each screen still feeds `isLevelUnlocked`,
  `stars()`, and the same navigation; the widget only draws. The six existing trail widget tests
  (via the hub smoke tests) still pass.

## Data-class content localized (§4.5) — CONFIRMED

Hebrew authored for: game catalog titles+taglines (6), achievements names+descriptions (25),
mission titles (6), avatar names (26) + unlock labels, pet stage names (7), NQ difficulty
labels+subtitles + skill labels + boss names, Shape habitat labels+subtitles + guardian names,
Clock world labels+subtitles + guardian names, Money world labels+subtitles + guardian names,
Memory world labels+subtitles + guardian names, Word Wizard chapter labels+subtitles + spell-boss
names. Resolved via `context.tr(domain, key, englishFallback)` so English is byte-identical.

## Chrome localized this phase

Hub + all hub screens (shop, achievements, missions, pet, admin [title + reset kept English in both
locales by design — dev tool], avatar picker), all six game home + trail screens, the NQ home
how-to dialog, and the NQ settings screen (which also gained a mirrored language toggle, §5.1).

## Separation: CONFIRMED vs ASSUMED

- **CONFIRMED:** build web success; 58 tests pass; engine + ownership move + RTL fixes + LTR islands
  + trail redesign + font selection compile and run; English literals preserved (tests prove it);
  Hebrew chrome + RTL verified by the new tests.
- **ASSUMED (human check needed):**
  - Hebrew font glyphs render correctly in a real browser (no tofu) — not verifiable headlessly.
  - Visual polish of the redesigned trail in RTL on a device.
  - Hebrew TTS voice (`he-IL`) is explicitly OUT OF SCOPE here (Phase 2).

## Out of scope (not built, by design)

Phase 2 Hebrew Word Wizard word bank; Phase 3 ₪ Money Math coin set + coin info map; Phase 4
multiplication world. Only the chrome/data Hebrew strings are in Phase 1.

## In-round game-screen chrome note

The engine, `context.l10n`, and all catalog hooks are in place. The highest-visibility chrome
(hub, hub screens, all game home + trail screens, world/difficulty/boss/guardian labels, dialogs,
settings) is localized. A small amount of deep in-round text on the game/result screens (e.g. live
feedback words, some result captions, guardian intro lines) still falls back to English in Hebrew
mode; these are isolated `Text` literals that can be swapped to `context.l10n`/`context.tr` in a
follow-up without any architectural change. Flagged for the reviewer as the known remaining gap.
