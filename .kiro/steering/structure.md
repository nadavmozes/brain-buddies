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
│  ├─ models/                   # game_catalog, avatar catalog, achievements
│  ├─ services/                 # player_profile (shared), feedback_service,
│  │                            #   sound_bridge / _stub / _web
│  ├─ theme/app_theme.dart      # Comic palette, borders, shadows
│  └─ widgets/                  # comic_button, comic_panel, star_row,
│                               #   coin_pill, xp_bar, confetti
└─ games/
   ├─ number_quest/             # models / services / screens / widgets
   └─ shape_safari/             # models / services / screens / widgets
```

## Rules

- **Shared state** (coins, equipped avatar, achievements) lives in
  `core/services/player_profile.dart` and is created once at the hub and passed
  into each game. Games must NOT keep their own coin balance.
- **Per-game progress** (level stars, XP, best score) stays in that game's own
  state store under `games/<game>/services/`.
- Reusable UI goes in `core/widgets`. Game-specific widgets stay in the game.
- Import depth from a game screen to core is `../../../core/...`.

## Adding a new game

1. Create `lib/games/<game>/` with its own models/screens/services.
2. Add a `GameEntry` in `core/models/game_catalog.dart` (`available: true`).
3. Pass the shared `PlayerProfile` into its entry screen and route from
   `game_hub_screen.dart`.
