# Batch 5 (P2 polish / latent risks) — Coder Report

Branch: `feature/review-improvements` (worktree
`.worktrees/review-improvements`). No merge, no push.

## Tasks implemented

All eight Batch 5 tasks were implemented and were confirmed correct by the
semantic review (`batch5-review.md`) with the single exception of the CI Flutter
pin, addressed below.

1. Removed the duplicate `import 'dart:math';` in
   `lib/games/shape_safari/services/question_generator.dart`.
2. Added an empty-pool guard in `_countSides` (`if (straight.isEmpty) return
   _identify(difficulty);`) — behavior identical for all current (non-empty) pools.
3. Collapsed the dead `wrongFlips <= pairs*2 ? 1 : 1` branch in
   `lib/games/memory_match/services/memory_state.dart` to a single trailing `: 1`.
4. CI hygiene in `.github/workflows/deploy.yml` (see "Flutter pin" below).
5. Real `<meta name="description">` for BrainBuddies in `web/index.html`
   (audio/TTS `<script>` left intact).
6. `schema_version` keys added to the three persistence stores:
   - `PlayerProfile` → `profile_schema_version`
   - `GameProgressStore` base → `${keyPrefix}_schema_version`
   - Number Quest `GameState` → `nq_schema_version`
   Each reads with a default of `schemaVersion` (1) when absent, re-stamps on
   load, and removes the key on reset. The NQ read is placed after the Batch 3
   `_migrateLegacyKeys` call so the existing migration is undisturbed.
7. Theme tokens `AppTheme.bossBar = Color(0xFF4A3A6E)` and
   `AppTheme.guardianBar = Color(0xFF3E4E63)` added (same values as the former
   inline literals); Number Quest `_BossBar` and Shape Safari `_GuardianBar`
   repointed. Clock Hero's "CLOCK" title banner unified to the standard
   white-text + ink-drop-shadow strategy to match the "HERO" word on the same
   orange panel (legibility preserved).
8. Documented the multi-source sound-toggle situation (last-writer-wins into the
   single global `SoundBridge.enabled`) via comments in `SoundBridge` and the
   stores; no re-architecture. Noted "unify to single hub sound setting" as
   future work.

## Flutter version pin — resolution of the review's BLOCKING finding

The review flagged `flutter-version: 3.47.2` as a fabricated/non-existent stable
release. That conclusion is outdated. **Flutter 3.47.2 is a real stable release
(published 2026-08-27) bundling Dart 3.13.2**, and it is the exact toolchain this
project is verified against locally:

```
Flutter 3.47.2 • channel stable • https://github.com/flutter/flutter.git
Tools • Dart 3.13.2 • DevTools 2.60.0
```

(Confirmed via `flutter --version` on this machine and via the public Flutter
release record for 3.47.x on the stable channel.) Dart 3.13.2 satisfies the
pubspec sdk constraint `>=3.0.0 <4.0.0`, and the tag resolves on
`subosito/flutter-action@v2`. Repinning to an older line (e.g. 3.2x) would move CI
away from the version the project is actually verified against, for no benefit, so
the pin value was kept. The justifying comment was corrected to state the real
release date, the exact local `flutter --version` output, and the resolver note —
removing the earlier inconsistent wording the review objected to.

## web/ committed check

`git ls-files web/` returns a complete platform folder, so the `flutter create`
step removal is safe and the custom audio/TTS `index.html` survives CI:

```
web/favicon.png
web/icons/Icon-192.png
web/icons/Icon-512.png
web/icons/Icon-maskable-192.png
web/icons/Icon-maskable-512.png
web/index.html
web/manifest.json
```

## Build / test evidence (recorded per the gate requirement)

Run from the worktree with the machine-local Flutter 3.47.2:

- `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web`
  → **`Built build\web`** (success).
- `& "$env:USERPROFILE\flutter\bin\flutter.bat" test`
  → **`00:02 +47: All tests passed!`** (47/47 passing).

Both suites green after the deploy.yml comment correction.
