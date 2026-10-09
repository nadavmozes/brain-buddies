# Product Overview

**BrainBuddies** is a comic-book styled hub of educational mini-games for kids in
grades 1-3. Players pick a game from the hub and learn through play.

## Games (6, all playable)

- **Number Quest** (🔢) — math: addition, subtraction, multiplication, division.
- **Shape Safari** (🔺) — shapes, patterns, early geometry.
- **Word Wizard** (🔤) — spelling & vocabulary.
- **Clock Hero** (🕒) — telling time (read, set, elapsed).
- **Money Math** (💰) — counting coins, making amounts, comparing money.
- **Memory Match** (🧠) — flip-and-pair card matching.

Every game uses the same shape: **worlds → trail map → levels ending in a friendly
boss/guardian**, with per-level stars, fastest-time records, and a live timer.

## Shared player profile & hub systems

Coins, the equipped avatar, achievements, the **hub-wide daily streak**, a **pet
companion** (grows with cross-game XP), and **daily missions** are all **shared
across all games** via the hub-level `PlayerProfile`. Per-game progress (level
stars, fastest times) stays local to each game. The shop, achievements, missions
board, and pet are **hub-level general actions** reachable from the main app, not
from inside a single game.

Games report hub-wide progress with a single call at round end:
`profile.onRoundFinished(correct, coinsEarned, threeStars, bossBeaten)` — this
advances the streak, feeds the pet, and ticks daily missions.

## Audience & tone

- Kids 6-9. Keep everything **friendly and non-scary** (e.g. bosses are befriended
  animals, not monsters to "defeat"; wrong answers give encouraging feedback).
- Big tap targets, minimal text, playful comic styling.

## Monetization

- Coins are earned in-game (no purchase). Cosmetic-only spending.
- One premium avatar is priced at **$1.99** but is **disabled / "Coming Soon"** for
  now (shown grayed out). No real IAP is wired yet.

## Platforms

Flutter app targeting Android, iOS, and web. Web is used for quick play-testing
(served locally via `demo/server.js`).
