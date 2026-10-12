# 🧠 BrainBuddies

A comic-book styled **hub of educational mini-games** for kids in **grades 1–3**
(ages 6–9). Built with **Flutter**, so it runs on **Android**, **iOS**, and the
**web** from a single codebase. Kids pick a game from the hub and learn through play.

**▶️ Play it live:** https://nadavmozes.github.io/brain-buddies/

Fully **bilingual — English and Hebrew (עברית)** with complete right-to-left (RTL)
support. The app auto-detects the device/browser language on first launch and can be
switched any time with an in-app **EN ⇄ עב** toggle.

All six games are playable, and the hub ties them together with a shared coin
economy, avatars, achievements, a daily streak, a growing pet companion, and daily
missions.

## 🎮 Games

Every game follows the same friendly shape: **worlds → a winding trail map → levels
ending in a friendly boss/guardian** (befriended, never "defeated"), with per-level
**stars**, **fastest-time** records, and a live timer.

| Game | Teaches |
|------|---------|
| 🔢 **Number Quest** | Addition, subtraction, multiplication, division |
| 🔺 **Shape Safari** | Identify shapes, count sides, finish patterns |
| 🔤 **Word Wizard** | Spelling & vocabulary — English words, or a dedicated **Hebrew** word set in Hebrew mode |
| 🕒 **Clock Hero** | Telling time — read, set, and elapsed time |
| 💰 **Money Math** | Counting coins, making amounts, comparing money, making change — **US cents (¢)** in English, **Israeli shekels/agorot (₪)** in Hebrew, with a tap-open coin info map |
| 🧠 **Memory Match** | Flip-and-pair card matching |

**Number Quest** also includes a **Times Tables** campaign (multiplication 1–12) with a
visual "build-the-fact" array that shows `a × b` as a grid to count.

## ✨ Hub-wide systems (shared across all games)

- **Coins** — earned in every game, spent on cosmetic avatars (no real-money purchases).
- **Avatar shop** — 26 avatars. Some are coin-buyable; many are **unlocked by playing**
  (beat a game's boss, grow your pet, keep a daily streak, master all six games). Earned
  avatars show their requirement and a progress hint, then a **CLAIM 🎁** button.
- **Achievements** — ~25 badges for milestones across every game.
- **Daily streak** — a hub-wide streak that grows each day you play.
- **Pet companion** — a buddy that grows from Egg → Dragon on cross-game XP, with a
  little celebration moment at the end of each round.
- **Daily missions** — three rotating goals each day, with coin rewards.
- **Daily Challenge** — a rotating bonus round reachable from the hub.

Games report a round with a single hook — `profile.onRoundFinished(correct,
coinsEarned, threeStars, bossBeaten)` — which advances the streak, feeds the pet, and
ticks missions. Per-game progress (stars, fastest times) stays local to each game.

## 🌍 Languages (English + Hebrew)

- **Two languages:** English (`en`) and Hebrew (`he`/עברית), selectable with an in-app
  toggle; the first-launch default follows the device/browser locale.
- **Full RTL:** in Hebrew the whole UI mirrors right-to-left — hub, trail maps, headers,
  and dialogs — while numbers, math equations (`3 × 4`), clock readouts, and money
  amounts stay left-to-right so they read naturally.
- **Localized content, not just chrome:** game names, world/level/boss names,
  achievements, missions, avatars, pet stages, and every in-game prompt are translated.
  Word Wizard uses a separate **Hebrew word set** (Hebrew-only questions in Hebrew mode),
  and Money Math switches to **₪ currency** with Hebrew coin names.
- **Hebrew-capable font** applied per locale (Fredoka + Heebo fallback); English keeps
  Baloo 2.

## ♿ Accessibility & audience

- Answer feedback is **not color-only** — correct/wrong tiles also show a check/cross
  icon, so it works for red-green color-blind kids.
- Big tap targets, minimal text, friendly non-scary tone, capped to a phone-width frame.

## 🛠️ Tech

- **Flutter** (Dart SDK **3.0+**), package name `brain_buddies`.
- Dependencies: `shared_preferences` (local persistence), `google_fonts` (Baloo 2 for
  English, a Hebrew-capable font for Hebrew), `flutter_localizations` + `intl` (locale
  wiring/RTL), `url_launcher`.
- Localization uses a lightweight in-repo string table (`lib/core/l10n/`) so both UI
  chrome and game *content* are translatable; language is stored in the shared profile.
- **No audio assets** — sound effects are **synthesized in JS** (Web Audio) through a
  `SoundBridge` web/stub split.
- All progress is stored **locally** on the device (web uses the browser's storage).
  There is no account or cloud sync.

## 📁 Project structure

Code is split into a **shared hub/core** and self-contained **per-game** folders, so a
new game drops in cleanly.

```
lib/
├─ main.dart                    # Boots BrainBuddiesApp
├─ app/                         # Hub shell + hub-level screens
│  ├─ brain_buddies_app.dart    # Root MaterialApp: theme + 430px width cap
│  ├─ game_hub_screen.dart      # Grid of games; hosts the shared PlayerProfile
│  ├─ shop_screen.dart          # Avatar shop (coin-buy + unlockable avatars)
│  ├─ achievements_screen.dart  # Achievements shelf
│  ├─ missions_screen.dart      # Daily missions board
│  ├─ pet_screen.dart           # Pet companion
│  └─ avatar_picker.dart        # Equip an owned avatar
├─ core/                        # Shared across ALL games
│  ├─ models/                   # game_catalog, avatar, achievement, mission, pet
│  ├─ services/                 # player_profile (shared state), game_progress_store
│  │                            #   (base for per-game stores), analytics_service,
│  │                            #   feedback_service, sound_bridge*/
│  ├─ theme/app_theme.dart      # Comic palette, borders, shadows
│  └─ widgets/                  # comic_button, comic_panel, star_row, coin_pill,
│                               #   xp_bar, confetti, timer_chip, answer_badge,
│                               #   pet_round_moment, game_header, reward_row, ...
└─ games/
   ├─ number_quest/   ├─ shape_safari/   ├─ word_wizard/
   ├─ clock_hero/     ├─ money_math/     └─ memory_match/
```

Each game folder is self-contained with its own `models/`, `services/` (a question
generator + a `ChangeNotifier` progress store), `screens/`, and `widgets/`.

### Adding a new game

1. Create `lib/games/<your_game>/` following the shared pattern (world/level model, a
   generator with `forLevel(...)` + de-dup, a progress store extending
   `GameProgressStore`, and the home → trail → game → result screens).
2. Add a `GameEntry` in `lib/core/models/game_catalog.dart` (`available: true`).
3. Pass the shared `PlayerProfile` in and route from `lib/app/game_hub_screen.dart`.

Reuse anything in `lib/core/` (theme, widgets, sound) across games.

## 🚀 Getting started

### 1. Install Flutter

- Download: https://docs.flutter.dev/get-started/install
- Verify: `flutter --version` and `flutter doctor`

### 2. Get dependencies

```bash
flutter pub get
```

### 3. Run it

```bash
flutter run                 # on a connected device/emulator
flutter run -d chrome       # in the browser (fastest, no Android/iOS setup)
```

## ▶️ Playing in the browser locally

```bash
flutter build web
node demo/server.js build/web      # then open http://localhost:8000
```

`demo/server.js` is a tiny zero-dependency static file server included in the repo.

> Browsers block audio until the first tap, so the very first click unlocks the sound
> effects; everything after that plays normally.

## 🌐 Deployment

The live site is hosted on **GitHub Pages** and deploys automatically on every push to
`main` via `.github/workflows/deploy.yml` (it runs the tests, builds the web app with
the correct base href, and publishes). The CI pins the Flutter version for reproducible
builds, and the `web/` platform folder is committed so the custom audio/speech JS is
always used.

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

The suite covers hub/game navigation plus the highest-risk logic: streaks, missions
(including midnight rollover), level unlocking, star-scoring thresholds, every question
generator (with a seeded RNG), avatar unlocks, and the shared progress store.

## 📝 Notes

- Requires Dart SDK **3.0+** (see `environment` in `pubspec.yaml`).
- Package name is `brain_buddies` (used in `package:` imports).
- Sound effects are **synthesized in code** (Web Audio) — no audio files are bundled.
- ⚠️ `flutter analyze` can crash if the project path contains non-ASCII characters
  (e.g. Hebrew). Building, testing, and running are unaffected; use `flutter build web`
  as the compiler check, or move the project to an ASCII path if you want the analyzer.
