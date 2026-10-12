# Phase 1 — Hebrew/English localization + RTL + trail redesign

The branch adds a full English/Hebrew localization foundation with a live runtime toggle and RTL support, exactly along the lines the design doc specifies. It builds an in-repo string table (not gen-l10n/ARB), lifts `PlayerProfile` ownership from the hub to `BrainBuddiesApp` so language can drive `MaterialApp.locale`, fixes the §5.2 hard-coded-direction sites, wraps the math/clock/money LTR islands, selects a Hebrew-capable font per locale, localizes the data catalogs via an id→Hebrew lookup with English fallback, and replaces the six per-game trail widgets with a single RTL-aware `TrailMapView`. Phase-2/3/4 content (Hebrew word bank, ₪ coin set, multiplication world) is correctly left unbuilt.

Watch for: nothing blocking. The author honestly flags (confirmed) a known residual gap — a small amount of deep in-round game/result text still falls back to English in Hebrew mode. This is isolated `Text` literals, not an architectural miss, and is out of the Phase-1 chrome/data scope as scoped. Hebrew glyph rendering and RTL visual polish are (confirmed) author-flagged as needing a human browser pass, which headless tests cannot cover.

**Verdict**: APPROVED

## High-level view

The localization engine lives in `lib/core/l10n/` as `AppLang` (en/he with locale/direction helpers), `AppStrings` (abstract + `EnStrings`/`HeStrings`), an `L10n` `InheritedNotifier` over the profile, and a `LocalizedCatalog` id→Hebrew map. The engine is in-repo, not gen-l10n, per §4.1. English chrome values are byte-identical to the previous literals, which is what keeps the English-asserting tests green.

Language state is additive and backward compatible. `PlayerProfile` gains `AppLang lang`, a new `profile_lang` key, `setLang()`, auto-detect-from-locale on first launch (en for any non-Hebrew locale, including the en_US test env), and a `reset()` that removes the new key and returns to en. `schemaVersion` stays 1 and no existing key is renamed.

The ownership move is clean: `PlayerProfile` + `AnalyticsService` are now created and loaded in `BrainBuddiesApp`, which wraps `MaterialApp` in an `AnimatedBuilder` over the profile so the toggle rebuilds the whole tree live. `locale`, `supportedLocales [en, he]`, and the three Global localizations delegates are wired, and the 430px width cap is preserved inside the `builder`.

RTL is handled by flipping `Directionality` app-wide via the locale, then fixing the concrete sites: the shared back button mirrors and flips its arrow, the hub profile bar uses `EdgeInsetsDirectional`/`PositionedDirectional`, and all six trail maps route through one `TrailMapView` whose node alignment and connector painter are direction-aware. The math equation, digital clock read-out, and money amount choices are each wrapped in an LTR `Directionality` island; the clock face canvas was already LTR and is untouched.

The trail redesign is a shared widget that only draws — every screen still feeds it `isLevelUnlocked`, `stars()`, and the same navigation push, so unlock/star behavior is unchanged. Sizing uses `LayoutBuilder`/`constraints.maxWidth`; no `MediaQuery.of(context).size` sizing was introduced anywhere in `lib`.

<details>
<summary>Issues (1)</summary>

1. **Residual in-round English fallback (non-blocking)** — some deep game/result-screen text (live feedback words, some result captions, guardian intro lines) still renders English in Hebrew mode. Author-flagged, isolated `Text` literals, swappable in a follow-up with no architectural change; outside the Phase-1 chrome/data scope. No action required to ship Phase 1.

</details>

<details>
<summary>Details</summary>

### Localization engine — in-repo string table (§4.1) — confirmed

`lib/core/l10n/app_lang.dart` defines `enum AppLang { en, he }` with `locale`, `direction`, `isRtl`, `code`, `fromCode`, and `fromLocale` (he/iw → he, else en). `app_strings.dart` is an abstract `AppStrings` with `EnStrings`/`HeStrings`; `l10n.dart` is an `L10n` `InheritedNotifier<Listenable>` over the profile exposing `context.l10n`/`context.lang`/`context.isRtl`/`context.tr`, with a const English `_fallback` so widgets pumped without an `L10n` ancestor degrade to English instead of throwing (`l10n.dart:38-46`). This is the in-repo table the spec chose over gen-l10n/ARB, and it is the right call because the data catalogs need localizing too.

`localized_catalog.dart:22-30` resolves Hebrew by domain+key and returns the passed-in English `fallback` whenever the language is English or a Hebrew value is missing — English is not duplicated, so there is no drift risk against the `const` catalogs. This directly satisfies §4.5.

### English literal preservation (test determinism, §4.6) — confirmed

`EnStrings` values match the previous hard-coded literals exactly: `hubTagline` = `'Pick a game and start learning!'`, `play` = `'PLAY'`, `comingSoon` = `'Coming Soon'`, `avatarShop` = `'Avatar Shop'`, `todaysMissions` = `"Today's Missions"` (`app_strings.dart:131-320`). Because the test env locale is en_US and no `profile_lang` key is seeded, auto-detect yields en and the English-asserting widget tests still find their literals. `$1.99` and `Number Quest` come through the catalog/avatar fallback path, which returns the English literal unchanged.

### Language state + ownership move (§4.2) — confirmed

`player_profile.dart` adds `_lang`, the additive `_kLang = 'profile_lang'` key, `setLang()` (persist + notify, `player_profile.dart:198-203`), and load-time auto-detect from `platformDispatcher.locale` when the key is absent (`player_profile.dart:150-158`). `schemaVersion` is unchanged at 1; `reset()` adds `remove(_kLang)` and sets `_lang = AppLang.en`. No existing key is renamed — every `profile_*` key is identical to main.

`brain_buddies_app.dart` now owns `PlayerProfile` + `AnalyticsService`, loads them in `initState`, and wraps `MaterialApp` in `AnimatedBuilder(animation: _profile)`. `locale: lang.locale`, `supportedLocales: const [Locale('en'), Locale('he')]`, and the three `Global*Localizations.delegate`s are present. The 430px cap survives inside `builder` (`ClipRect` → `SizedBox(width: 430)`), with `L10n` wrapping `child` so `context.l10n` works tree-wide. The hub receives the profile/analytics via constructor and still owns the six game stores and reset wiring per the evidence note.

### RTL fix sites (§5.2) + LTR islands (§4.3) — confirmed

`all_games_back_button.dart` mirrors via `Row` under `Directionality` and flips the arrow with `Transform.flip(flipX: rtl)` so "back" still points to the start. The hub `_ProfileBar` streak margin became `EdgeInsetsDirectional.only(end: 8)` and both badges became `PositionedDirectional(end: …)`; the EN⇄עב `_LangToggle` pill calls `profile.setLang(...)`. All six trail maps route through `TrailMapView`, whose `_TrailRow` uses `AlignmentDirectional.centerStart/centerEnd` and whose `_ConnectorPainter.sideX` resolves start/end to physical left/right from the ambient direction — so the winding path mirrors with no per-game branching.

The three LTR islands are wrapped: the NQ equation `Text(problem.question)` (`game_screen.dart`), the Clock digital time choice grid (`clock_game_screen.dart`), and the Money amount choice grid (`money_game_screen.dart`) are each inside `Directionality(textDirection: TextDirection.ltr, …)`. The clock face `TextPainter` LTR arg was already correct and is unchanged, as the spec requires.

### Trail redesign with identical unlock/stars behavior — confirmed

`lib/core/widgets/trail_map.dart` is a new shared `TrailMapView` + `TrailNodeData`: circular medallion nodes, bigger boss/guardian nodes, a dashed `CustomPaint` connector, locked/unlocked/completed states with `StarRow`. Sizing is `LayoutBuilder`/`constraints.maxWidth` (`trail_map.dart:63-70`) — never `MediaQuery.size`. The per-game screens (e.g. `shape_safari/screens/trail_map_screen.dart`) now build `TrailNodeData` from the same `state.isLevelUnlocked(level)`, `state.stars(level.id)`, and the identical `Navigator.push` as before; the widget only draws. Unlock/star logic stayed in the game stores untouched.

### Font (§4.4) — confirmed resolves, visual check deferred

`app_theme.dart` `AppTheme.build([AppLang lang])` keeps `baloo2TextTheme` for en and uses `fredokaTextTheme` for he, with `fontFamilyFallback` = `[Heebo, Baloo 2]` so mixed EN/HE + emoji degrade gracefully. The toggle swaps the font live via the `AnimatedBuilder`. The author (confirmed) flags that real-browser glyph rendering can't be validated headlessly — a human visual pass remains.

### Extension-import gotcha — not reintroduced

Screens that read enum extension getters (e.g. `habitat.label`, `habitat.color`) still import their defining files, and the trail screens add `import '../../../core/l10n/l10n.dart';` for `context.tr`/`context.l10n`. The build-web success in the evidence is the compiler check (analyze is unreliable on the Hebrew path per steering), and no getter-not-defined breaks are present.

### Scope discipline — confirmed

`git diff --name-only` shows no changes to `word_bank`, `word_generator`, `money_question`, `money_generator`, `money_level`, any coin set, `wizard_level`, `boss.dart`, `skill.dart`, `difficulty.dart`, or any `times_table`/multiplication file. Phase 2 (Hebrew word bank), Phase 3 (₪ coins + info map), and Phase 4 (multiplication world) are correctly deferred. `pubspec.yaml` adds only `flutter_localizations` (SDK), which needs no CI change.

### Tests — reported green, new coverage present

The evidence note records build web success and 58 passing (55 baseline + 3 new), with analyze skipped per steering. `test/localization_test.dart` adds three widget tests: persisted `profile_lang=he` renders Hebrew chrome and asserts `Directionality == rtl`; the empty-prefs/en_US default stays English + LTR; and the toggle flips chrome live and to RTL. These assert against `HeStrings`/`EnStrings` instances, so they track the real string table. Not independently re-run per instructions; evidence is specific and corroborated by the diff.

</details>

<details>
<summary>File map</summary>

- `lib/core/l10n/app_lang.dart` — new: AppLang enum + locale/direction/detect helpers.
- `lib/core/l10n/app_strings.dart` — new: abstract AppStrings + En/He implementations (English = prior literals).
- `lib/core/l10n/l10n.dart` — new: L10n InheritedNotifier + context extensions + English fallback.
- `lib/core/l10n/localized_catalog.dart` — new: id→Hebrew data-catalog lookup, English-as-fallback.
- `lib/core/services/player_profile.dart` — lang state, additive profile_lang key, setLang, reset handling, auto-detect.
- `lib/app/brain_buddies_app.dart` — profile/analytics ownership moved up; locale/delegates/supportedLocales; AnimatedBuilder; L10n wrap; 430px cap kept.
- `lib/core/theme/app_theme.dart` — locale-aware font (Baloo 2 / Fredoka + Heebo fallback).
- `lib/core/widgets/all_games_back_button.dart` — RTL mirror + arrow flip + localized label.
- `lib/core/widgets/trail_map.dart` — new shared RTL-aware TrailMapView + TrailNodeData.
- `lib/app/{game_hub,shop,achievements,missions,pet,avatar_picker,admin}_screen.dart` — localized chrome; hub lang toggle + directional insets/badges.
- six `*_home_screen.dart` + six `*trail*/*map*_screen.dart` — localized labels, chevron flips, adopt TrailMapView.
- three game screens (NQ/clock/money) — LTR islands wrapped.
- `lib/games/number_quest/screens/{difficulty,settings}_screen.dart` — localized; settings gains mirrored language toggle.
- `pubspec.yaml` — add flutter_localizations (SDK).
- `test/localization_test.dart` — new he/RTL/toggle tests.
- `.agents/tasks/i18n-foundation/verification.md` — build+test evidence.

Full diff: `git -C .worktrees/i18n-foundation diff main...feature/i18n-foundation`

</details>
