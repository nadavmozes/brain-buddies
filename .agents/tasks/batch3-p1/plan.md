# Implementation Plan — Batch 3 P1 (shared-base refactor + persistence/data safety)

High-risk batch. Correctness and NOT changing user-visible behavior or breaking
saved progress are paramount. All work in the worktree
`c:\Users\USER\OneDrive\מסמכים\Math Adventure\.worktrees\review-improvements`
on branch `feature/review-improvements`. Commit locally; never push/merge.

VERIFY (Windows PowerShell; `;` not `&&`):
- Build: `& "$env:USERPROFILE\flutter\bin\flutter.bat" build web` — SUCCESS = `Built build\web` present. A trailing `Exit Code: 1` from Select-String with no match after the Built line is NOT a failure.
- Test: `& "$env:USERPROFILE\flutter\bin\flutter.bat" test` — all pass (currently 10 tests).
- Do NOT run `flutter analyze` (crashes on the non-ASCII path).

---

## Confirmed facts (from reading the code)

### Exact shared_preferences keys per store (MUST stay byte-identical)

Shape Safari (`lib/games/shape_safari/services/safari_state.dart`):
- `safari_best` (int), `safari_rounds` (int), `safari_sound` (bool),
  `safari_befriended` (StringList),
  per level: `safari_level_<id>` (stars int), `safari_fastest_<id>` (seconds int).

Word Wizard (`lib/games/word_wizard/services/wizard_state.dart`):
- `wizard_best`, `wizard_rounds`, `wizard_sound`,
  per level: `wizard_level_<id>`, `wizard_fastest_<id>`.

Clock Hero (`lib/games/clock_hero/services/clock_state.dart`):
- `clock_best`, `clock_rounds`, `clock_sound`,
  per level: `clock_level_<id>`, `clock_fastest_<id>`.

Money Math (`lib/games/money_math/services/money_state.dart`):
- `money_best`, `money_rounds`, `money_sound`,
  per level: `money_level_<id>`, `money_fastest_<id>`.

Memory Match (`lib/games/memory_match/services/memory_state.dart`):
- `memory_rounds`, `memory_sound` (NO `memory_best` — Memory has no bestCorrect),
  per level: `memory_level_<id>`, `memory_fastest_<id>`.

So the shared per-level/sound/rounds keys are formed as `<prefix>_level_<id>`,
`<prefix>_fastest_<id>`, `<prefix>_sound`, `<prefix>_rounds`, where
`prefix ∈ {safari, wizard, clock, money, memory}`. `_best` exists for all
except Memory. `safari_befriended` is Safari-only.

### Number Quest (`lib/games/number_quest/services/game_state.dart`) bare keys — to namespace with migration (Task 2)

Current BARE keys written by GameState:
- `xp` (int)
- `sound_on` (bool)
- `best_answer_streak` (int)
- `mult_correct` (int)
- per level: `level_<id>` (stars), `fastest_<id>` (seconds), ids like `easy_0`.
- per skill (via `SkillInfo.key = 'skill_<name>'`, in `models/skill.dart`):
  `skill_addition_correct`, `skill_addition_attempts`,
  `skill_subtraction_correct`, `skill_subtraction_attempts`,
  `skill_multiplication_correct`, `skill_multiplication_attempts`,
  `skill_division_correct`, `skill_division_attempts`.

NOTE: `daily_streak` / `last_day` were already removed in Batch 1 (confirmed: no
such keys in game_state.dart today).

**NQ migration map (old bare -> new `nq_` key):**
- `xp` -> `nq_xp`
- `sound_on` -> `nq_sound_on`
- `best_answer_streak` -> `nq_best_answer_streak`
- `mult_correct` -> `nq_mult_correct`
- `level_<id>` -> `nq_level_<id>` (for every `WorldMap.allLevels` id)
- `fastest_<id>` -> `nq_fastest_<id>` (for every `WorldMap.allLevels` id)
- `skill_<name>_correct` -> `nq_skill_<name>_correct` (4 skills)
- `skill_<name>_attempts` -> `nq_skill_<name>_attempts` (4 skills)

Migration rule: on load, for each specific old key GameState owns, if the new
`nq_` key is ABSENT but the old bare key EXISTS, copy old -> new and remove the
old key. Migrate ONLY these exact keys (never other stores' keys). The simplest
safe implementation enumerates exactly this fixed key set.

### completeLevel signatures / return types / call sites

- Safari: `Future<SafariOutcome> completeLevel({required PlayerProfile profile, required SafariLevel level, required int correct, required int total, required bool guardianBefriended, int elapsedSeconds = 0})`. Call site: `lib/games/shape_safari/screens/safari_game_screen.dart`.
- Wizard: `Future<WizardOutcome> completeLevel({required PlayerProfile profile, required WizardLevel level, required int correct, required int total, required int elapsedSeconds})`. Call site: `lib/games/word_wizard/screens/wizard_game_screen.dart`.
- Clock: `Future<ClockOutcome> completeLevel({required PlayerProfile profile, required ClockLevel level, required int correct, required int total, required int elapsedSeconds})`. Call site: `lib/games/clock_hero/screens/clock_game_screen.dart`.
- Money: `Future<MoneyOutcome> completeLevel({required PlayerProfile profile, required MoneyLevel level, required int correct, required int total, required int elapsedSeconds})`. Call site: `lib/games/money_math/screens/money_game_screen.dart`.
- Memory: `Future<MemoryOutcome> completeLevel({required PlayerProfile profile, required MemoryLevel level, required int wrongFlips, required int elapsedSeconds})`. Call site: `lib/games/memory_match/screens/memory_game_screen.dart`.
- NQ (NOT refactored): `Future<LevelOutcome> completeLevel({required PlayerProfile profile, required GameLevel level, required int correct, required int total, required int roundScore, required int bestAnswerStreak, required bool bossDefeated, int elapsedSeconds = 0})`. Call site: `lib/games/number_quest/screens/game_screen.dart`.

Each `*Outcome` class differs in field set (Safari: guardianBefriended/isNewBest/isNewFastest; Clock: guardianGreeted; Money/Wizard: isNewBestScore; Memory: perfect/isNewFastest, no bestScore). These signatures and Outcome shapes MUST be preserved so screens compile unchanged.

### percent -> stars thresholds (identical across the 4 "correct/total" games)

`percent = total==0 ? 0 : round(correct/total*100)`; `stars = percent>=90?3 : percent>=70?2 : percent>=50?1 : 0`.
Memory is DIFFERENT (by wrongFlips): `perfect = wrongFlips==0`; `stars = wrongFlips==0?3 : wrongFlips<=pairs?2 : 1` (always ≥1 for finishing).

Keep-best stars: write new stars only if `> prevStars`.
Fastest: only when `stars==3 && elapsedSeconds>0 && (prevFastest==0 || elapsedSeconds<prevFastest)`.

### Coin formulas & achievements (MUST stay identical)

- Safari: `correct*3 + stars*5 + (guardianBefriended?20:0)`; ids: firstGame; (perfect) perfectRound; (3★) threeStar; (fastest) speedster; (befriended) guardianFriend; (whole habitat trail cleared) shapeExplorer.
- Wizard: `correct*3 + stars*5 + (bossBeaten?20:0)` where `bossBeaten = level.isBoss && percent>=70`; ids: firstGame; (correct==total) perfectRound + spellMaster; threeStar; speedster.
- Clock: `correct*3 + stars*5 + (guardianGreeted?20:0)` where `guardianGreeted = level.isBoss && percent>=70`; ids: firstGame; (correct==total) perfectRound + timeKeeper; threeStar; speedster.
- Money: `correct*3 + stars*5 + (bossBeaten?20:0)` where `bossBeaten = level.isBoss && percent>=70`; ids: firstGame; (correct==total) perfectRound + moneyMaster; threeStar; speedster.
- Memory: `pairs*3 + stars*5 + (bossBeaten?20:0)` where `bossBeaten = level.isBoss`; ids: firstGame; (perfect) perfectRound + memoryMaster; threeStar; speedster. `onRoundFinished(correct: pairs, ...)`.
- NQ (unchanged): `correct*2 + stars*5 + (bossDefeated?25:0)`.

All five end with `profile.onRoundFinished(correct/pairs, coinsEarned, threeStars: stars==3, bossBeaten: <boss flag>)`.

### dailyLevel / onRoundFinished interpretation (Task 5)

`WorldMap.dailyLevel([now])` (in `lib/games/number_quest/models/level.dart`)
doc: "uses a stable id that never appears in the map (so it never affects
unlock/star progression)". It uses `index: 999`, so its id (e.g. `easy_999`) is
NOT in `WorldMap.allLevels`. In `game_state.completeLevel` the fastest-time
block is guarded by `onMap = WorldMap.allLevels.any((l)=>l.id==level.id)`, so a
daily round does NOT record stars-as-progress-gate (stars still write to its own
unique id but that id gates nothing) and does NOT set a fastest record. It DOES
award coins/XP/achievements and calls `onRoundFinished` (feeding streak, pet,
missions, analytics).
NQ home (`number_quest_home_screen.dart`) ALREADY has a "Daily Challenge" button
pushing `GameScreen(level: WorldMap.dailyLevel(), ..., isDaily: true)`.

**Interpretation:** The daily challenge is designed to feed hub systems
(streak/pet/missions/analytics via onRoundFinished) but NOT affect unlock/star
progression — and today it already behaves that way. Task 5 = add a hub-level
"Daily Challenge" tile that reproduces the existing NQ daily launch (reuse NQ's
GameScreen with `WorldMap.dailyLevel()` and `isDaily: true`). We KEEP the
onRoundFinished call (do NOT suppress it) because the existing design already
calls it and only skips the on-map fastest/unlock effects.

---

## Ordered implementation steps

### Task 1 + Task 2 — refactor + NQ namespacing (do first, one green build/test)

- [ ] 1. Create the shared base `GameProgressStore` (abstract `ChangeNotifier`) in
      `lib/core/services/game_progress_store.dart`. It owns: `SharedPreferences? prefs`,
      `bool loaded`, `bool soundOn`, `Map<String,int> levelStars`, `Map<String,int> levelFastest`;
      getters `isLoaded`, `soundOn`, `stars(id)`, `totalStars`, `fastestSeconds(id)`,
      `overallFastest`, `hasFastest`; `isLevelUnlocked<T>` logic via an abstract
      `List<String> get orderedLevelIds` (subclass returns its `allLevels.map((l)=>l.id)`);
      `load()` reading `<prefix>_sound` + `<prefix>_level_<id>`/`<prefix>_fastest_<id>`
      for `orderedLevelIds`, setting `SoundBridge.enabled`; `setSoundOn(bool)`;
      `reset()` clearing sound + per-level keys; and protected helpers:
      `starsForPercent(int percent)` (90/70/50 thresholds), `keepBestStars(id, stars)`
      (writes only if improved, returns effective), `recordFastestIfBest(id, stars, seconds)`
      (returns bool isNewFastest, 3★+improved guard). Abstract members a subclass
      supplies: `String get keyPrefix`, `List<String> get orderedLevelIds`.
      Keep key strings EXACTLY `<prefix>_...` as today.
      Files: `lib/core/services/game_progress_store.dart`
      Verify: build web succeeds (file compiles).

- [ ] 2. Refactor the FOUR "correct/total" siblings (Wizard, Clock, Money, Safari)
      to extend `GameProgressStore`, keeping each one's OWN `completeLevel`
      signature, Outcome class, coin formula, achievement ids, extra fields
      (`_bestCorrect`/`_kBest`/`_roundsPlayed` for Wizard/Clock/Money; `_befriended`
      + `safari_befriended` + habitat-trail achievement for Safari), and `reset()`
      extras. Replace the duplicated stars/fastest/sound/isLevelUnlocked/load
      plumbing with base calls; compose `starsForPercent`, `keepBestStars`,
      `recordFastestIfBest` inside each `completeLevel`. Override `load()`/`reset()`
      to call `super` then handle extras (best/rounds/befriended). Do NOT change any
      key string, default, coin value, or achievement id.
      Files: `lib/games/word_wizard/services/wizard_state.dart`,
      `lib/games/clock_hero/services/clock_state.dart`,
      `lib/games/money_math/services/money_state.dart`,
      `lib/games/shape_safari/services/safari_state.dart`
      Verify: build web succeeds.

- [ ] 3. Refactor Memory (`memory_state.dart`) to extend `GameProgressStore`,
      keeping its `wrongFlips`-based `completeLevel`, Memory star formula
      (3 if 0 wrong, else 2 if ≤pairs, else 1), `perfect`, no `_best`,
      `memory_rounds`/`memory_sound` keys, and achievement ids
      (perfectRound + memoryMaster). Use base for stars/fastest maps,
      load/reset of per-level + sound keys, `isLevelUnlocked`,
      `recordFastestIfBest`. Memory computes its own stars (NOT via
      `starsForPercent`).
      Files: `lib/games/memory_match/services/memory_state.dart`
      Verify: build web succeeds; `flutter test` passes (money_make_change_test,
      word_wizard_speaker_test, analytics_test, widget_test — 10 tests).

- [ ] 4. Namespace Number Quest prefs to `nq_*` with one-time migration in
      `game_state.dart`. Change key constants `_kXp`→`nq_xp`, `_kSound`→`nq_sound_on`,
      `_kBestStreak`→`nq_best_answer_streak`, `_kMultCorrect`→`nq_mult_correct`;
      per-level `nq_level_<id>`/`nq_fastest_<id>`; per-skill
      `nq_<skill.key>_correct`/`nq_<skill.key>_attempts` (skill.key already
      `skill_<name>`, so result is `nq_skill_<name>_...`). Add a private
      `_migrateLegacyKeys(SharedPreferences p)` called at the start of `load()`
      BEFORE reads: for each specific old bare key in the fixed set (listed in the
      migration map above, enumerating `WorldMap.allLevels` and `Skill.values`),
      if the `nq_` key is absent and the old key exists, copy value then
      `p.remove(old)`. Update `reset()` to remove the new `nq_` keys. Leave the
      rest of GameState (XP/level logic, SkillStat, completeLevel, onMap daily
      guard) UNCHANGED. (Decision: NQ is NOT folded onto the base — see note below.)
      Files: `lib/games/number_quest/services/game_state.dart`
      Verify: build web succeeds; `flutter test` passes.

- [ ] 5. Add unit tests for the refactor's behavior-preservation and NQ migration.
      New test file `test/progress_store_test.dart`:
      (a) seed `SharedPreferences.setMockInitialValues` with legacy sibling keys
      (e.g. `safari_level_jungle_0: 2`, `safari_fastest_jungle_0: 10`,
      `wizard_sound: false`) and assert each refactored store's `load()` reads
      them identically (stars/fastest/sound);
      (b) NQ migration: seed bare `xp: 100`, `sound_on: false`,
      `level_easy_0: 3`, `fastest_easy_0: 12`, `skill_addition_correct: 7`;
      load GameState; assert values preserved AND new `nq_*` keys written AND old
      bare keys removed AND unrelated keys (e.g. a fake `safari_best`) untouched.
      Files: `test/progress_store_test.dart`
      Verify: `flutter test` passes (now >10 tests).

### Task 3 — mission day-rollover across midnight

- [ ] 6. In `player_profile.dart`, add private `void _ensureMissionDay()` (sync, no
      persist) + `Future<void> _rolloverMissionsIfNeeded()` that, when
      `_missionDay != _todayKey()`, resets `_missionProgress`/`_missionClaimed`,
      sets `_missionDay = today`, and persists (mirrors load()'s else-branch).
      Call it at the START of `reportMission(...)` and `claimMission(...)` BEFORE
      applying the operation. Keep `todaysMissions` using `DateTime.now()` and the
      deterministic `Missions.forDay` rotation unchanged.
      Files: `lib/core/services/player_profile.dart`
      Verify: build web + `flutter test` pass.

- [ ] 7. Add a mission-rollover unit test: set `_missionDay` to a prior day via a
      seeded pref (`profile_mission_day` = yesterday) plus stale progress/claimed,
      load, then call `reportMission` and assert progress is reset to just the new
      amount and `profile_mission_day` is today; and that `forDay` rotation for a
      fixed date is deterministic.
      Files: `test/mission_rollover_test.dart` (or extend an existing profile test)
      Verify: `flutter test` passes.

### Task 4 — pet round-moment on result screens

- [ ] 8. In `player_profile.dart`, make `addPetXp` record the round delta/level
      change: add fields `int _lastRoundPetXp`, `bool _lastRoundPetLeveledUp`,
      `int _lastRoundPetNewLevel`, `bool _lastRoundPetStageChanged` with public
      getters. In `onRoundFinished`, reset these then capture before/after pet
      level and stage around `addPetXp(coinsEarned)` (compare
      `Pet.stageForLevel`). Expose `lastRoundPetXp`, `lastRoundPetLeveledUp`,
      `lastRoundPetStageChanged`, `lastRoundPetNewLevel`, plus `petStage`.
      These are transient (not persisted). Keep existing pet-achievement logic.
      Files: `lib/core/services/player_profile.dart`
      Verify: build web + `flutter test` pass.

- [ ] 9. Create a shared `PetRoundMoment` widget in `lib/core/widgets/pet_round_moment.dart`:
      given a `PlayerProfile`, render a small friendly comic panel showing the
      pet emoji + "+<xp> Buddy XP" and, if `lastRoundPetStageChanged` (or
      leveled up), a "Buddy grew!" banner (comic style via AppTheme; reuse
      `ComicPanel`). Non-scary, compact; render nothing if `lastRoundPetXp <= 0`.
      Files: `lib/core/widgets/pet_round_moment.dart`
      Verify: build web succeeds.

- [ ] 10. Insert `PetRoundMoment(profile: widget.profile)` into all SIX result
      screens, right after the main reward `ComicPanel` (before `DoubleAwardsButton`).
      For NQ, trigger the pet-grew celebration consistently (confetti already
      shows on 3★/boss/levelUp). Keep edits identical in shape across files.
      Files: `lib/games/number_quest/screens/result_screen.dart`,
      `lib/games/shape_safari/screens/safari_result_screen.dart`,
      `lib/games/word_wizard/screens/wizard_result_screen.dart`,
      `lib/games/clock_hero/screens/clock_result_screen.dart`,
      `lib/games/money_math/screens/money_result_screen.dart`,
      `lib/games/memory_match/screens/memory_result_screen.dart`
      Verify: build web + `flutter test` pass.

### Task 5 — daily challenge in the hub

- [ ] 11. Add a hub-level "Daily Challenge" entry in `game_hub_screen.dart` that
      launches today's Number Quest daily level. Add a method that lazy-loads
      `_numberQuestState` (same as `_openNumberQuest`), calls
      `_profile.recordGamePlayed(GameCatalog.numberQuest.id, GameCatalog.all.length)`,
      then pushes `GameScreen(level: WorldMap.dailyLevel(), state: _numberQuestState!,
      profile: _profile, isDaily: true)` (import NQ `GameScreen` + `WorldMap`).
      Surface it as a tile/row in `_hubActions()` (reuse `_ActionButton`, emoji 📅).
      KEEP onRoundFinished behavior (the daily round still ticks streak/pet/
      missions/analytics; it does not affect star/unlock progression — see
      interpretation). Note generalizing to all six games as future work.
      Files: `lib/app/game_hub_screen.dart`
      Verify: build web succeeds; `flutter test` passes (optionally extend
      widget_test to tap "Daily Challenge" and assert the NQ game screen appears,
      using a 430x900+ surface).

---

## Per-task behavior-preservation checklist

Task 1 (refactor 5 siblings):
- [ ] Every pref key byte-identical: `<prefix>_level_<id>`, `<prefix>_fastest_<id>`,
      `<prefix>_sound`, `<prefix>_rounds`, `<prefix>_best` (not Memory),
      `safari_befriended` (Safari only). Verified by step-5 load tests.
- [ ] Each `completeLevel` signature + Outcome class + fields unchanged (screens compile without edits).
- [ ] Coin formulas unchanged per game (3/5/20; Memory pairs*3; see facts).
- [ ] Achievement id sets unchanged per game (incl. moneyMaster/timeKeeper/spellMaster/memoryMaster, guardianFriend, shapeExplorer habitat-trail check).
- [ ] percent→stars thresholds 90/70/50 unchanged; Memory wrongFlips formula unchanged.
- [ ] keep-best-stars and fastest-only-on-3★-and-improved unchanged.
- [ ] `isLevelUnlocked` = previous in order has ≥1 star; first level always unlocked.
- [ ] `SoundBridge.enabled` synced on load/setSoundOn/reset.
- [ ] `onRoundFinished(correct/pairs, coinsEarned, stars==3, bossFlag)` still called once per completeLevel.

Task 2 (NQ namespacing + migration):
- [ ] Only the fixed NQ key set is migrated; no other store's keys touched.
- [ ] Existing players keep XP/stars/fastest/skills/sound (migration copies old→nq_).
- [ ] New installs (no old keys) just use `nq_*` defaults.
- [ ] `reset()` removes the `nq_*` keys.
- [ ] NQ gameplay/XP/level/daily-onMap-guard logic otherwise unchanged.

Task 3 (mission rollover):
- [ ] Rollover resets progress+claimed and updates `_missionDay` before applying report/claim past midnight.
- [ ] `Missions.forDay` deterministic rotation unchanged.
- [ ] load()'s existing reset path unchanged / consistent with the helper.

Task 4 (pet moment):
- [ ] Pet XP still equals coinsEarned (addPetXp unchanged in effect); only transient delta/level/stage flags added.
- [ ] Flags reset each round; not persisted.
- [ ] Result screens show a small friendly moment; nothing when delta<=0; non-scary.

Task 5 (daily tile):
- [ ] Daily round still calls onRoundFinished (streak/pet/missions/analytics tick).
- [ ] Daily does NOT affect star/unlock progression (unique off-map id + onMap guard).
- [ ] Reuses existing NQ GameScreen + dailyLevel; no new daily engine.

---

## Decision notes

- **Number Quest is NOT folded onto `GameProgressStore` this batch.** game_state.dart
  carries SkillStat accuracy tracking, hero XP/level derivation, adaptive-difficulty
  inputs, a different coin formula (`correct*2`), extra achievements
  (streak5/bossFriend/multMaster/heroLevel5), `roundScore`/`xpEarned`, and the
  on-map daily-challenge guard. Forcing it onto the base is high risk for little
  gain. We only namespace its keys (Task 2). Recommend revisiting NQ in a later batch.
- **Base shares primitives, not a single `completeLevel`.** The five siblings differ
  (Memory uses wrongFlips + its own star curve; Safari takes `guardianBefriended`
  and has befriended-set + habitat-trail achievement; Money/Clock/Wizard track
  `_bestCorrect`). A one-size `completeLevel` on the base would force unification
  that risks changing behavior, so each subclass keeps its own `completeLevel`
  composing the base helpers (`starsForPercent`, `keepBestStars`,
  `recordFastestIfBest`) and the shared maps/getters/load/reset plumbing. This
  preserves every signature and stored key.
- **Daily challenge keeps onRoundFinished.** The dailyLevel doc says it must not
  affect unlock/star progression; the current code already honors that via the
  off-map id and `onMap` guard while still feeding hub systems. The hub tile
  reproduces the existing NQ launch, so behavior is unchanged.
