---
inclusion: always
---

# Project Structure

Code is split into shared **hub/core** and self-contained **per-game** folders.

```
lib/
├─ main.dart                    # Boots BrainBuddiesApp
├─ app/                         # Hub shell
│  ├─ brain_buddies_app.dart    # Root MaterialApp: theme + 430px width cap
│  ├─ game_hub_screen.dart      # Grid of games; hosts shared PlayerProfile
│  └─ (hub shop / achievements screens live here too)
├─ core/                        # Shared across ALL games
│  ├─ models/                   # game_catalog, avatar, achievement,
│  │                            #   mission, pet
│  ├─ services/                 # player_profile (shared), feedback_service,
│  │                            #   feedback_email, sound_bridge / _stub / _web
│  ├─ theme/app_theme.dart      # Comic palette, borders, shadows
│  └─ widgets/                  # comic_button, comic_panel, star_row, coin_pill,
│                               #   xp_bar, confetti, timer_chip,
│                               #   double_awards_button
├─ app/                         # hub screens: game_hub, shop, achievements,
│                               #   missions, pet, avatar_picker
└─ games/
   ├─ number_quest/             # worlds → level map → boss battles
   ├─ shape_safari/             # habitats → trail map → guardian encounters
   ├─ word_wizard/              # chapters → spellbook path → Spell Master boss
   ├─ clock_hero/               # time-of-day worlds → trail → guardian
   ├─ money_math/               # piggy/wallet/vault worlds → trail → guardian
   └─ memory_match/             # animal/fruit/space decks → trail → guardian
```

## Hub-wide shared systems (in PlayerProfile)

- **Daily streak** (`recordPlayDay`), a **pet** that grows with cross-game XP
  (`addPetXp`, stages in `core/models/pet.dart`), and **daily missions**
  (`core/models/mission.dart`, rotated by date).
- Games call one hook at round end:
  `onRoundFinished(correct, coinsEarned, threeStars, bossBeaten)` which bundles
  streak + pet growth + mission progress. Do NOT re-implement these per game.

All four games are playable. Each game folder is self-contained with its own
`models/`, `services/`, `screens/`, and (where needed) `widgets/`.

## Shared per-game pattern

Every game follows the same proven shape, so new ones should too:

- **A world/level model** (`<game>_level.dart` or similar): an enum of worlds
  with theme color + difficulty, a `<Game>Level` (id, questionCount, difficulty,
  `isBoss`), and a `<Game>Map` with `levelsPer...` + `allLevels` in play order.
  The final level of each world is a friendly **boss/guardian** (never scary).
- **A question generator** with a static `forLevel(level)` that uses the world's
  difficulty and **de-duplicates** questions within a round (seen-set + retry
  guard, ~25 tries).
- **A per-game state** (`ChangeNotifier`): per-level **stars** and **fastest
  time** maps, `isLevelUnlocked` (previous level in `allLevels` needs ≥1 star),
  and `completeLevel(...)` that awards **shared** coins/achievements via
  `PlayerProfile` while keeping stars/times local. Fastest time only counts on a
  3-star run.
- **Screens**: a home that is a **world select**, a **trail/map** screen (winding
  path, locked/unlocked nodes, stars), a **game** screen (live `TimerChip`), and a
  **result** screen (stars, coins, time, `DoubleAwardsButton`, and
  Next-level / Back-to-map / Play-again actions).

## Rules

- **Shared state** (coins, equipped avatar, achievements) lives in
  `core/services/player_profile.dart` and is created once at the hub and passed
  into each game. Games must NOT keep their own coin balance.
- **Per-game progress** (level stars, XP, best score) stays in that game's own
  state store under `games/<game>/services/`.
- Reusable UI goes in `core/widgets`. Game-specific widgets stay in the game.
- Import depth from a game screen to core is `../../../core/...`.

## Adding a new game

1. Create `lib/games/<game>/` following the **Shared per-game pattern** above
   (world/level model, generator with `forLevel` + de-dup, `ChangeNotifier`
   state with per-level stars/fastest, and the four screens).
2. Add a `GameEntry` in `core/models/game_catalog.dart` (`available: true`).
3. Pass the shared `PlayerProfile` into its entry screen, route from
   `game_hub_screen.dart`, and call
   `profile.recordGamePlayed(GameCatalog.<id>.id, GameCatalog.all.length)` in
   the hub open method (powers the "Explorer" achievement).
