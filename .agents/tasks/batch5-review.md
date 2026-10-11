# Batch 5 (P2 polish / latent risks) — Semantic Review

Batch 5 is five commits on `feature/review-improvements` (`ba2472e` → `01b2a53`,
base `cb6dc4f`): trivial P2 cleanups, a CI hardening pass, schema-version
future-proofing of the three persistence stores, theme-token extraction plus a
Clock Hero banner unification, and documentation of the multi-source sound
toggle. The diff is small (12 files, +80/-17) and the code-level changes are, with
one exception, exactly what the tasks asked for and behavior-preserving where
required.

Two things block approval. First, the CI change pins `flutter-version: 3.47.2`,
which is **not a real Flutter release** and whose accompanying comment is
internally inconsistent (it claims this version "bundles Dart 3.13.2", but Dart
3.13.2 does not ship with any 3.4x Flutter — Flutter 3.13.x bundles Dart 3.1.x).
Task 4 explicitly says to flag a version that was guessed without sound reasoning;
this reads as a fabricated pin that would make the deploy fail to resolve the
toolchain. Second, there is **no recorded build/test evidence** for Batch 5
anywhere in `.agents/` (no `batch5` task dir, no coder report, no review JSON with
a `Built build\web` / `flutter test` result). The review brief says to READ that
evidence and, if it is missing entirely, to reject with a finding rather than
re-running the suites. It is missing.

**Watch for:** fabricated Flutter version pin (confirmed); missing Batch 5
build/test evidence (confirmed).

**Verdict**: CHANGES_REQUESTED

<details>
<summary>Issues (2)</summary>

1. **Fabricated Flutter version pin** — `deploy.yml` pins `flutter-version: 3.47.2`, which is not a real stable release, and its comment's "bundles Dart 3.13.2" claim is impossible for that version. Repin to a real stable Flutter whose bundled Dart ≥ 3.0.0 and correct the comment.
2. **Missing Batch 5 build/test evidence** — no coder report / `Built build\web` or `flutter test` result is recorded anywhere in `.agents/` for this batch. Record the green build + test evidence (the brief forbids re-running the suites here).

</details>

---

## Task 1 — duplicate `dart:math` import removed

Intent met (confirmed). `lib/games/shape_safari/services/question_generator.dart`
previously opened with `import 'dart:math';` twice; the diff removes the second
line, leaving a single `import 'dart:math';` at the top and no new duplicate
introduced elsewhere in the file. No behavioral impact.

## Task 2 — `_countSides` empty-pool guard

Intent met (confirmed). The guard `if (straight.isEmpty) return _identify(difficulty);`
is inserted immediately after `straight` is built and before the
`straight[_rng.nextInt(straight.length)]` index. When the pool is non-empty the
guard is skipped and the original code path runs unchanged, so behavior is
identical for every current pool (all of which contain straight-sided shapes).
The fallback to `_identify` is a sensible same-signature question type. No finding.

## Task 3 — memory_match stars dead-branch collapse

Intent met (confirmed). The old expression ended
`... : wrongFlips <= pairs*2 ? 1 : 1` — both arms of the inner ternary returned
`1`, so it always evaluated to `1`. The diff collapses it to a single trailing
`: 1 // always at least 1 for finishing`. The `== 0 → 3` and `<= pairs → 2` arms
are untouched, so the scoring result is identical for all inputs. No finding.

## Task 4 — CI workflow (deploy.yml) — BLOCKING

Several sub-parts are correct, but the Flutter pin is a blocking defect.

- **Flutter version pin (BLOCKING, confirmed).** The pin is `flutter-version: 3.47.2`.
  No such stable Flutter release exists (stable Flutter is in the ~3.0–3.3x range;
  there is no 3.4x line). The justifying comment states this version "bundles
  Dart 3.13.2 [which] satisfies the pubspec sdk constraint '>=3.0.0 <4.0.0'", but
  that pairing is impossible — Dart 3.13.2 would ship with Flutter ~3.13.x, not
  3.4x. The pubspec constraint `>=3.0.0 <4.0.0` is wide, so almost any Flutter 3.x
  would satisfy it, but a non-existent version string will cause
  `subosito/flutter-action@v2` to fail resolving the toolchain and break the
  deploy. This is exactly the "guessed without reasoning" case Task 4 says to
  flag. Fix: pin a real stable version whose bundled Dart ≥ 3.0.0 (e.g. a current
  stable like 3.24.x / 3.27.x), and correct the comment to state that version's
  actual bundled Dart. Pinning itself is the right call; the value is wrong.
- **Node-20-deprecated action bumps (met, confirmed).** `actions/checkout` v4→v5 and
  `actions/upload-pages-artifact` v3→v4 are bumped. `actions/deploy-pages` was
  already at v4 (no change needed). There is no `configure-pages` or any `setup-*`
  action in this workflow, so those parts of the checklist are N/A — nothing was
  missed.
- **`flutter create` removal (met, confirmed).** The `flutter create . --platforms=web`
  step is replaced with a NOTE explaining the committed `web/` is used instead.
  `git ls-files web/` confirms the folder is fully committed: `index.html`,
  `manifest.json`, `favicon.png`, and four icons. So `flutter build web` has
  everything it needs and the custom audio/TTS `index.html` cannot be clobbered.
  Sound decision. (The brief asked that the coder confirm this via `git ls-files web/`;
  I verified it directly since no coder report records it.)
- **Audio/TTS survival (met, confirmed).** Because the custom `web/index.html` is
  committed and the build no longer regenerates it, the synthesized-audio + TTS
  JS survives CI.
- **Unchanged invariants (met, confirmed).** `--base-href "/${{ github.event.repository.name }}/"`,
  the `concurrency: pages` + `cancel-in-progress` group, and the `flutter test`
  gate before build are all present and unchanged.

## Task 5 — web/index.html meta description

Intent met (confirmed). `<meta name="description">` changes from the default
"A new Flutter project." to a real friendly description naming BrainBuddies and
the six game topics for grades 1-3. It is the only line changed in the file, so
the audio/TTS `<script>` block is left intact. No finding.

## Task 6 — schema_version future-proofing

Intent met (confirmed). All three stores — `PlayerProfile`
(`profile_schema_version`), the shared `GameProgressStore` base
(`${keyPrefix}_schema_version`), and Number Quest `GameState`
(`nq_schema_version`) — add `static const int schemaVersion = 1`, read the key
with `?? schemaVersion` (default 1 when absent), and re-stamp it on load. Each
also removes its schema key on reset. In `GameState.load`, the schema read is
placed AFTER `_migrateLegacyKeys(p)`, so the Batch 3 legacy-key migration runs
first and is undisturbed. No existing keys are touched; the change is additive and
non-breaking. The `final _ = p.getInt(...)` pattern discards the read value (no
migration branch yet), which is fine for pure future-proofing. No finding.

## Task 7 — encounter-bar theme tokens + Clock Hero banner

Intent met (confirmed). `AppTheme.bossBar = Color(0xFF4A3A6E)` and
`AppTheme.guardianBar = Color(0xFF3E4E63)` are added with the SAME values as the
previous inline literals. Number Quest's `_BossBar` and Shape Safari's
`_GuardianBar` are repointed to the tokens, so there is no visual change for those
two bars. The Clock Hero banner is unified to the documented
white-text + ink-drop-shadow strategy: "CLOCK" switches from `ink` text / white
`offset(2,2)` shadow to `white` text / `AppTheme.ink` `offset(3,3)` shadow,
matching the "HERO" word directly below it (which already used that exact
treatment on the same orange panel). This is the "unify to white-text + ink-shadow"
option the task allows, and the comment documents the legibility reasoning. No
finding.

## Task 8 — multi-source sound-toggle documentation

Intent met (confirmed). `SoundBridge.enabled` gains a substantial doc comment
spelling out that the single global flag is written from several independent
`sound_on` booleans (`PlayerProfile.soundOn`, each `GameProgressStore`, and NQ's
`GameState`), that the effective state is "last writer wins", why that is
acceptable in practice (any toggle updates the flag immediately), and that unifying
to a single hub-wide source is future work. Matching short notes are added at each
`setSoundOn` write site and the base-store load. No code was re-architected, so no
behavior changed and no tests were put at risk. This is the conservative,
documentation-only approach the task preferred. No finding.

## Build / test evidence — BLOCKING

No Batch 5 build or test evidence exists (confirmed). There is no `batch5` task
directory under `.agents/tasks/`, no coder report file, and no review JSON
recording a `flutter build web` → `Built build\web` result or a `flutter test`
pass count for this batch. The review brief requires reading the coder's recorded
evidence and, if it is missing entirely, rejecting with a finding rather than
re-running the suites. The evidence is absent, so this is a blocking gap on its
own. (The changes are small and look compilable — the theme-token repoints and
the `_countSides` guard are the only code paths that could affect compilation, and
both reference symbols that exist — but "looks compilable" is not the recorded
green build/test the gate requires.)

## Branch / merge safety

Confirmed clean. `git status` shows a clean working tree on
`feature/review-improvements`. `git branch -a --contains ba2472e` lists only
`feature/review-improvements`, and `origin/main` / `main` sit at `0f10ec2`
(pre-batch), so Batch 5 was committed in logical chunks on the feature branch and
was NOT merged or pushed.

---

<details>
<summary>File map</summary>

- `.github/workflows/deploy.yml` — Flutter pin (WRONG value 3.47.2), checkout v5 / upload-pages-artifact v4 bumps, flutter-create dropped with web/ note.
- `lib/core/services/game_progress_store.dart` — schema_version const + load re-stamp + reset removal; sound last-writer-wins note.
- `lib/core/services/player_profile.dart` — same schema_version pattern + reset removal; sound note.
- `lib/core/services/sound_bridge.dart` — multi-source "last writer wins" doc on `enabled`.
- `lib/core/theme/app_theme.dart` — `bossBar` / `guardianBar` tokens.
- `lib/games/clock_hero/screens/clock_hero_home_screen.dart` — "CLOCK" banner unified to white + ink shadow.
- `lib/games/memory_match/services/memory_state.dart` — stars dead-branch collapsed to `: 1`.
- `lib/games/number_quest/screens/game_screen.dart` — `_BossBar` repointed to `AppTheme.bossBar`.
- `lib/games/number_quest/services/game_state.dart` — schema_version pattern after legacy migration.
- `lib/games/shape_safari/screens/safari_game_screen.dart` — `_GuardianBar` repointed to `AppTheme.guardianBar`.
- `lib/games/shape_safari/services/question_generator.dart` — duplicate import removed; `_countSides` empty-pool guard.
- `web/index.html` — real BrainBuddies meta description.

Full diff: `git -C <worktree> diff cb6dc4f..01b2a53`
</details>
