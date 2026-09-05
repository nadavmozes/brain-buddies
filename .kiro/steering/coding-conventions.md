---
inclusion: always
---

# Coding Conventions & Gotchas

Hard-won rules for this codebase. Following them avoids repeat bugs and wasted
build cycles.

## Dart / Flutter

- **Extension methods need their file imported.** Enums here expose data via
  extensions (e.g. `DifficultyInfo.color`, `ShapeKindInfo.label`,
  `HabitatInfo.color`). If a file uses `x.color`/`x.label`, it MUST import the
  file that defines the extension, even if `x`'s type came in transitively.
  This has caused multiple `The getter '…' isn't defined` build failures.
- **Never size widgets from `MediaQuery.of(context).size.width`.** The app is
  capped to a 430px phone frame in `brain_buddies_app.dart`, but MediaQuery still
  reports the full browser window, producing giant/overflowing tiles. Use
  `LayoutBuilder` and `constraints.maxWidth` instead.
- Keep answer/choice grids inside `LayoutBuilder`; cap shape-tile height (~120px)
  so a 2×2 grid always fits without overflow.
- Prefer `const` constructors; match the existing comic style (thick ink borders,
  hard offset shadows via `AppTheme.comicShadow`).

## Navigation

- Gameplay is reached: Hub → GameHome → Map → GameScreen, then GameScreen
  `pushReplacement`s the Result screen. So **`Navigator.pop()` from a result goes
  back to the map** — use that for "Back to Map/Trail". Do NOT use
  `popUntil((r) => r.isFirst)` from a result; that jumps all the way to the hub.
- Result screens offer: **Next Level/Stop** (pushReplacement to the next level,
  only if cleared), **Back to Map/Trail** (pop once), **Play Again**
  (pushReplacement same level).

## State & persistence

- Shared player data (coins, avatar, achievements) → `core` `PlayerProfile`.
- Per-game progress (stars/XP) → the game's own store.
- All stores are `ChangeNotifier`s persisted with `shared_preferences`; UI listens
  via `AnimatedBuilder`. Namespace pref keys per store to avoid collisions.
- Keep `SoundBridge.enabled` in sync with the sound setting on load/toggle/reset.

## Sound

- Route SFX through `FeedbackService` (respects the sound toggle) which calls
  `SoundBridge`. Web audio unlocks on first user gesture — expected, not a bug.

## Credit-saving workflow

- Batch related edits, then run ONE `flutter build web` to catch all errors at
  once rather than building after each tiny change.
- After adding a new screen with different layout, extend the widget test with a
  phone-sized surface (`tester.view.physicalSize = const Size(430, 900)`).
- Reuse `core/widgets` instead of re-implementing buttons/panels/stars.
