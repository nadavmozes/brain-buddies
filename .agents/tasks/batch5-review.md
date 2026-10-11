# Batch 5 (P2 polish / latent risks) — Semantic Review (pass 2)

Batch 5 is six commits on `feature/review-improvements` (`ba2472e` → `429681f`,
base `cb6dc4f`): trivial P2 cleanups, a CI hardening pass, schema-version
future-proofing of the three persistence stores, encounter-bar theme-token
extraction plus a Clock Hero banner unification, and documentation of the
multi-source sound toggle. The sixth commit (`429681f`) addresses the two
blocking findings from pass 1 — it corrects the Flutter-pin comment and records
the build/test evidence. The diff is small (12 code/CI/web files, +80/-17) and
every change is either exactly what the task asked for or behavior-preserving
where required.

The pass-1 review rejected on two findings: a "fabricated" Flutter pin and
missing build/test evidence. Both are now resolved. The pin value `3.47.2` is a
**real** stable release — `flutter --version` on this machine reports
`Flutter 3.47.2 • channel stable … Tools • Dart 3.13.2`, which is the exact
toolchain the project is verified against locally; Dart 3.13.2 satisfies the
pubspec constraint `>=3.0.0 <4.0.0`. The pass-1 claim that no such release exists
was stale knowledge, not an environment check. Evidence is now recorded in
`batch5-report.md`: `Built build\web` and `00:02 +47: All tests passed!`.

**Watch for:** CI tag resolution — `3.47.2` matches the locally-verified toolchain
and is documented, but whether `subosito/flutter-action@v2` can resolve that exact
stable tag will only be proven on the first CI run (possible). This is a reasonable
documented choice, not a guess, so it does not block.

**Verdict**: APPROVED

## High-level view

The CI pin controversy from pass 1 is settled by checking the machine rather than
memory: `3.47.2` is installed, stable, bundles Dart 3.13.2, and satisfies the
pubspec SDK floor. The comment was rewritten to state the real release, the local
`flutter --version` output, and the resolver note, so the pin is now a documented,
defensible choice tied to the verified-against toolchain.

The deploy workflow's structural invariants are untouched: `--base-href`, the
`flutter test` gate before build, and the `concurrency: pages` + `cancel-in-progress`
group all survive unchanged. The deprecated-action bumps that matter are present
(checkout v4→v5, upload-pages-artifact v3→v4); deploy-pages was already v4, and
there is no `configure-pages`/`setup-*` to bump. Dropping `flutter create` is safe
because `git ls-files web/` shows the full platform folder is committed, so the
custom audio/TTS `index.html` cannot be clobbered.

The three persistence stores gain an additive `schema_version` key (default 1,
re-stamped on load, removed on reset) with no migration branch yet. The Number
Quest read is correctly sequenced after the Batch 3 legacy-key migration, so no
existing key or prior migration is disturbed.

The theme-token extraction and banner unification carry no visual change for the
two encounter bars (same hex values moved behind `AppTheme.bossBar` /
`AppTheme.guardianBar`); the Clock Hero "CLOCK" word is unified to the
white-text + ink-shadow strategy already used by "HERO" on the same panel. The
sound-toggle work is documentation-only — it names the last-writer-wins coupling
across stores without re-architecting anything, so no test was put at risk.

Build and test evidence is present and green, and the batch stayed on
`feature/review-improvements` — committed in logical chunks, not merged, not
pushed.

<details>
<summary>Issues (0)</summary>

No blocking, major, or minor findings. The two pass-1 blocking findings (Flutter
pin, missing evidence) are resolved. One informational watch item: first-CI-run
proof that `subosito/flutter-action@v2` resolves the `3.47.2` stable tag.

</details>

<details>
<summary>Details</summary>

## Task 1 — duplicate `dart:math` import removed

Intent met (confirmed). The file previously opened with `import 'dart:math';`
twice; the diff removes the second line, leaving a single import and no new
duplicate anywhere in the file.

## Task 2 — `_countSides` empty-pool guard

Intent met (confirmed). `if (straight.isEmpty) return _identify(difficulty);` is
inserted immediately after `straight` is built and before the
`straight[_rng.nextInt(straight.length)]` index. The guard is skipped whenever the
pool is non-empty — which is every current pool — so behavior is identical today;
the fallback only engages for a hypothetical future all-curved pool, where it
avoids an empty-list range error by returning a same-signature `_identify`
question.

## Task 3 — memory_match stars dead-branch collapse

Intent met (confirmed). The old tail was
`… : wrongFlips <= pairs*2 ? 1 : 1` — both inner arms returned `1`, so it was
dead. The diff collapses it to a single trailing `: 1`. The `== 0 → 3` and
`<= pairs → 2` arms are untouched, so the computed star count is identical for
every input.

## Task 4 — CI workflow (deploy.yml)

Intent met (confirmed). The pass-1 blocking concern on the pin is resolved.

The pin is `flutter-version: 3.47.2`. Checked against this environment,
`flutter --version` reports `Flutter 3.47.2 • channel stable … Framework …
2026-08-26 … Tools • Dart 3.13.2`. It is a real stable release and the exact
toolchain the project is verified against locally (steering places Flutter at
`%USERPROFILE%\flutter`). Dart 3.13.2 satisfies pubspec `sdk: ">=3.0.0 <4.0.0"`.
The accompanying comment now states the real release date, the local
`flutter --version` output, the SDK-constraint compatibility, and the resolver
note — a documented, defensible choice rather than a guess. The pass-1 assertion
that "no 3.4x stable exists" and "Dart 3.13.2 can't pair with it" was stale
version-timeline knowledge and is contradicted by the installed toolchain.

Residual (non-blocking, possible): whether `subosito/flutter-action@v2` can
resolve the exact `3.47.2` stable tag in CI is only provable on the first run.
Because the value matches the verified-against local toolchain and is documented,
this is an informational watch item, not a defect.

Node-20-deprecated action bumps (met, confirmed): `actions/checkout` v4→v5 and
`actions/upload-pages-artifact` v3→v4. `actions/deploy-pages` was already v4. There
is no `configure-pages` or any `setup-*` action in this workflow, so those checklist
items are genuinely N/A — nothing was missed.

`flutter create` removal (met, confirmed): the `flutter create . --platforms=web`
step is replaced with a NOTE explaining the committed `web/` is used instead.
`git ls-files web/` confirms the folder is fully committed (`index.html`,
`manifest.json`, `favicon.png`, four icons), so `flutter build web` has everything
it needs and the custom audio/TTS `index.html` cannot be clobbered — the audio/TTS
JS survives CI.

Unchanged invariants (met, confirmed): `--base-href "/${{ github.event.repository.name }}/"`,
the `concurrency: pages` + `cancel-in-progress` group, and the `flutter test` gate
before build are all present and unchanged.

## Task 5 — web/index.html meta description

Intent met (confirmed). `<meta name="description">` changes from the default
"A new Flutter project." to a friendly description naming BrainBuddies and the six
game topics for grades 1-3. It is the only line changed in the file, so the
audio/TTS `<script>` block is left intact.

## Task 6 — schema_version future-proofing

Intent met (confirmed). `PlayerProfile` (`profile_schema_version`), the shared
`GameProgressStore` base (`${keyPrefix}_schema_version`), and Number Quest
`GameState` (`nq_schema_version`) each add `static const int schemaVersion = 1`,
read with `?? schemaVersion` (default 1 when absent), re-stamp on load, and remove
the key on reset. In `GameState.load` the read is placed AFTER
`_migrateLegacyKeys(p)`, so the Batch 3 legacy-key migration runs first and is
undisturbed. The change is additive — no existing key is touched — and the
`final _ = p.getInt(...)` discards the read value, which is correct for pure
future-proofing with no migration branch yet. Non-breaking.

## Task 7 — encounter-bar theme tokens + Clock Hero banner

Intent met (confirmed). `AppTheme.bossBar = Color(0xFF4A3A6E)` and
`AppTheme.guardianBar = Color(0xFF3E4E63)` are added with the SAME values as the
former inline literals; Number Quest `_BossBar` and Shape Safari `_GuardianBar`
are repointed, so there is no visual change for either bar. The Clock Hero "CLOCK"
word is unified to the documented white-text + ink-drop-shadow strategy (from `ink`
text / white `offset(2,2)` shadow to `Colors.white` text / `AppTheme.ink`
`offset(3,3)` shadow), matching the "HERO" word directly below it on the same
orange panel. This is the "unify to white-text + ink-shadow" option the task
allows, with the legibility reasoning documented in the comment.

## Task 8 — multi-source sound-toggle documentation

Intent met (confirmed). `SoundBridge.enabled` gains a doc comment spelling out that
the single global flag is written from several independent `sound_on` booleans
(`PlayerProfile.soundOn`, each `GameProgressStore`, NQ's `GameState`), that the
effective state is last-writer-wins, why that is acceptable (any toggle updates the
flag immediately), and that unifying to one hub-wide source is future work.
Matching short notes are added at each `setSoundOn` write site and the base-store
load. No code was re-architected, so no behavior changed and no test was put at
risk — the conservative, documentation-only approach the task preferred.

## Build / test evidence

Present and green (confirmed). `batch5-report.md` records, run from the worktree
with the machine-local Flutter 3.47.2: `flutter build web` → `Built build\web`
(success) and `flutter test` → `00:02 +47: All tests passed!` (47/47). Per the
brief I read this recorded evidence rather than re-running the suites. The pass-1
gap (no recorded evidence) is resolved.

## Branch / merge safety

Confirmed clean. `git status -s` is empty (all work committed),
`git branch -a --contains ba2472e` lists only `feature/review-improvements`, and
`origin/main` / `main` sit at the pre-batch `0f10ec2`. Batch 5 was committed in
logical chunks on the feature branch and was NOT merged or pushed.

---

<details>
<summary>File map</summary>

- `.github/workflows/deploy.yml` — Flutter pin `3.47.2` (verified real, documented), checkout v5 / upload-pages-artifact v4 bumps, flutter-create dropped with web/ note; base-href, test gate, concurrency unchanged.
- `lib/core/services/game_progress_store.dart` — schema_version const + load re-stamp + reset removal; sound last-writer-wins note.
- `lib/core/services/player_profile.dart` — same schema_version pattern + reset removal; sound note.
- `lib/core/services/sound_bridge.dart` — multi-source "last writer wins" doc on `enabled`.
- `lib/core/theme/app_theme.dart` — `bossBar` / `guardianBar` tokens (same hex).
- `lib/games/clock_hero/screens/clock_hero_home_screen.dart` — "CLOCK" banner unified to white + ink shadow.
- `lib/games/memory_match/services/memory_state.dart` — stars dead-branch collapsed to `: 1`.
- `lib/games/number_quest/screens/game_screen.dart` — `_BossBar` repointed to `AppTheme.bossBar`.
- `lib/games/number_quest/services/game_state.dart` — schema_version pattern after legacy migration.
- `lib/games/shape_safari/screens/safari_game_screen.dart` — `_GuardianBar` repointed to `AppTheme.guardianBar`.
- `lib/games/shape_safari/services/question_generator.dart` — duplicate import removed; `_countSides` empty-pool guard.
- `web/index.html` — real BrainBuddies meta description; audio/TTS script intact.

Full diff: `git -C <worktree> diff cb6dc4f..429681f`
</details>

</details>
