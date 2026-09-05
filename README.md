# 🧠 BrainBuddies

A comic-book styled **hub of educational games** for kids in **grades 1–3**.
Built with **Flutter**, so it runs on **Android**, **iOS**, and the **web** from a
single codebase. Kids pick a game from the hub and start learning through play.

The first game is **🔢 Number Quest** (a full math adventure). More games are
scaffolded as "coming soon" cards so new ones drop straight into the hub.

## 🎮 Games

| Game | Status | What it teaches |
|------|--------|-----------------|
| 🔢 **Number Quest** | ✅ Playable | Addition, subtraction, multiplication, division |
| 🔤 Word Wizard | 🚧 Coming soon | Spelling & vocabulary |
| 🔺 **Shape Safari** | ✅ Playable | Identify shapes, count sides, finish patterns |
| 🕒 Clock Hero | 🚧 Coming soon | Telling the time |

### 🔺 Shape Safari features

- **Three habitats** (worlds), each a **trail** of stops ending in a friendly
  **guardian** animal: 🌿 Jungle (🦁 Leo), 🏜️ Desert (🐫 Cami), ⛰️ Mountain (🦅 Rocky).
- **Trail map with unlocks** — clear a stop (1+ star) to open the next.
- **Guardian encounters** — "photograph" the guardian by answering correctly;
  befriend it for bonus coins (kid-friendly, no "defeating").
- **Four question types**: identify a shape, find the named shape, count sides,
  and "what comes next?" patterns.
- Shapes are **drawn with a CustomPainter** (no image assets).
- Per-level **stars & coins**, best-score tracking, confetti and sound.
- Each habitat introduces more shapes; difficulty ramps along the trail.

### 🔢 Number Quest features

- **Three worlds** (roughly grade 1 → 3), each a map of levels ending in a **boss**:
  🌱 Easy · ⭐ Intermediate · 🔥 Expert
- **Level map with unlocks** — beat a level to open the next.
- **Distinct bosses per world** — GulPuff 🐡, Octo 🐙, Draco 🐲 (hearts-based battles).
- **Coins + hero shop**, **XP & hero levels**, **badges**, **daily streak & challenge**.
- **Adaptive difficulty**, **parent progress view**, and lots of **juice**: confetti,
  streak bonuses, and **synthesized sound effects** (correct/wrong/coin/level-up/victory).
- All progress saved locally via `shared_preferences`.

## 📁 Project structure

The code is split into **shared hub/core** and **per-game** folders, so adding a
new game is self-contained.

```
lib/
├─ main.dart                       # Boots the hub
├─ app/                            # Hub shell
│  ├─ brain_buddies_app.dart       # Root MaterialApp (title, theme, width cap)
│  └─ game_hub_screen.dart         # Grid of games to choose from
├─ core/                           # Shared across all games
│  ├─ models/game_catalog.dart     # Describes each game in the hub
│  ├─ theme/app_theme.dart         # Comic palette, borders, shadows
│  ├─ widgets/                     # comic_button, comic_panel, star_row,
│  │                               #   coin_pill, xp_bar, confetti
│  └─ services/                    # feedback_service, sound_bridge*
└─ games/
   └─ number_quest/                # The math game, fully self-contained
      ├─ models/                   # difficulty, level, boss, badge, skill,
      │                            #   hero_character, math_problem, round_result
      ├─ services/                 # game_state, problem_generator
      ├─ widgets/                  # hero_buddy
      └─ screens/                  # number_quest_home, difficulty, level_map,
                                   #   game, result, shop, badges, parent, settings
```

### Adding a new game

1. Create `lib/games/<your_game>/` with its own models/screens/services.
2. Add a `GameEntry` for it in `lib/core/models/game_catalog.dart` (set
   `available: true`).
3. Route to its entry screen from `_onTap` in `lib/app/game_hub_screen.dart`.

Reuse anything in `lib/core/` (theme, widgets, sound) across games.

## 🚀 Getting started

### 1. Install Flutter

- Download: https://docs.flutter.dev/get-started/install
- Verify: `flutter --version` and `flutter doctor`

### 2. Get dependencies

```bash
flutter pub get
```

(The `android/`, `ios/`, and `web/` platform folders are already generated. If
they're ever missing, run `flutter create .` to regenerate them without touching
`lib/`.)

### 3. Run it

```bash
flutter run                 # on a connected device/emulator
flutter run -d chrome       # in the browser (fastest, no Android/iOS setup)
```

## ▶️ Playing in the browser (no phone/emulator needed)

The web target needs only Flutter + Chrome. Build once, then serve the output:

```bash
flutter build web
node demo/server.js build/web      # then open http://localhost:8000
```

`demo/server.js` is a tiny zero-dependency static file server included in the repo.

> Note: browsers block audio until the first tap, so the very first click unlocks
> the sound effects, and everything after that plays normally.

## 📦 Building release versions

```bash
flutter build apk --release        # Android APK
flutter build appbundle --release  # Android App Bundle (Play Store)
flutter build ios --release        # iOS (needs macOS + Xcode)
flutter build web --release        # Web
```

## 🧪 Tests

```bash
flutter test
```

Includes a smoke test that opens the hub and launches Number Quest.

## 📝 Notes

- Requires Dart SDK **3.0+** (see `environment` in `pubspec.yaml`).
- Package name is `brain_buddies` (used in `package:` imports).
- All progress is stored locally on the device (web uses `localStorage`); there's
  no account or cloud sync.
- Sound effects are **synthesized in code** (Web Audio) — no audio files are bundled.
- `flutter analyze` can crash if the project path contains non-ASCII characters
  (e.g. Hebrew). Building, testing, and running are unaffected; move the project to
  an ASCII path if you want the analyzer.
