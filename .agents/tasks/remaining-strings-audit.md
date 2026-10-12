# Remaining English-String (i18n) Audit — `feature/i18n-foundation`

READ-ONLY audit of the worktree
`c:\Users\USER\OneDrive\מסמכים\Math Adventure\.worktrees\i18n-foundation`.
No code was modified. Every row marked **CONFIRMED** was read at the cited
file+line; rows marked **ASSUMPTION** are inferences noted as such.

---

## 1. Summary answer (the key finding)

The previous sweep localized the **hub, home screens, world/difficulty
selectors, trail/map node titles, result banners, and feedback text** correctly.
It MISSED one systematic category plus a handful of specific widgets:

> **Root cause pattern:** several display sites were deliberately left
> "byte-identical to English" and read the raw model getter
> (`level.title`, `guardian.name`, `boss.name`, `problem.operatorLabel`,
> `ShapeKind.label`) or a hard-coded literal, **instead of** the localized
> getter/`context.tr(...)` that the *trail screens already use for the exact
> same data*. The Hebrew values usually already exist in `localized_catalog.dart`
> or `app_strings.dart` — they are simply not read at these sites.

The biggest concrete leaks, in priority order:

1. **Every game-screen HEADER** (`*_game_screen.dart`) shows `level.title`
   ("Stop N", "Guardian", "Lesson N", "Spell Master", "Level N"/"BOSS") and the
   boss/guardian **name** in raw English — in all 6 games. Trail screens show the
   SAME nodes localized, so the leak is only on the in-round header. (leak #1)
2. **Number Quest math skill tag** ("ADDITION/SUBTRACTION/MULTIPLICATION/
   DIVISION") shown raw on the question card for the three difficulty worlds;
   only the Times Tables campaign is localized. `nq.skill.label` Hebrew EXISTS
   but is bypassed. (leak #4 — confirmed root cause)
3. **Clock Hero** — EVERY question prompt and spoken-time phrase is hard-coded
   English in the generator (`clock_generator.dart` + `ClockTime.spoken`). No
   Hebrew path exists at all. (leak #6)
4. **Shape Safari** — all question prompts and all shape names
   (`ShapeKind.label`) are hard-coded English and shown as prompts/choices;
   NO catalog keys exist yet. (newly found, large)
5. **`SoundToggleButton`** ("Sound: On/Off") hard-coded; used by all 5
   secondary game homes. (leak #3)
6. **Word Wizard speaker/voice** button should be REMOVED per the user (it reads
   the answer aloud). The Hebrew word bank IS correctly used in `he` mode. (leak #2 — see §6)
7. Misc hard-coded literals: `pet_round_moment.dart` ("Buddy", "Buddy grew!"),
   `parent_screen.dart` (whole screen), `settings_screen.dart` reset dialog +
   "LV"/"stars"/"coins", `skill.masteryLabel`.
8. The game "logo" split-text on each home (`'NUMBER'/'QUEST'`, `'CLOCK'/'HERO'`,
   …) is hard-coded. This is what the user sees as "the name of the games … in
   English" once inside a game. **Decision needed** (see §7).

Two UI-consistency items (streak 🔥 chip; NQ-only level indicator) are in §8.

---

## 2. What is ALREADY correct (not leaks — do not touch)

- Hub game cards use `L10n.of(context).tr('game.title'/'game.tagline', id, …)` and
  the Hebrew titles exist — `game_hub_screen.dart` `_GameCard` (CONFIRMED). The
  hub "coming soon" snackbar also localizes the title.
- All `*_home_screen` world/habitat/chapter selectors and all `*_trail/map`
  screens resolve labels via `context.tr('<game>.world.label'…)` and node titles
  via `s.levelN/stopN/lessonN/guardian/spellMaster/bossUpper` (CONFIRMED in
  `difficulty_screen.dart`, `level_map_screen.dart`, `clock_trail_screen.dart`,
  `spellbook_map_screen.dart`, `times_tables_map_screen.dart`).
- Money Math is fully localized: `money_generator.dart` branches prompts on `_he`
  and switches currency (USD¢ ↔ ₪/agorot); coin names via
  `usdCoinName`/`ilsCoinName`. The game screen resolves `_lang` via `L10n.read`
  in `initState`. This is the **correct reference pattern** (CONFIRMED).
- All result screens pull titles/labels from `context.l10n.*` getters that exist
  in both `EnStrings`/`HeStrings` (CONFIRMED in `result_screen.dart`).
- Hub action screens (shop, achievements, missions, pet, avatar_picker) import
  and use `l10n`; a scan found no raw `Text('Latin…')` in them (CONFIRMED by grep).
- Shape Safari `skillLabel` ('Identify'/'Find'/'Sides'/'Pattern') is assigned but
  **never displayed** — used only in dedup; NOT a leak (CONFIRMED: the only
  `.skillLabel` reference is its declaration).
- Math `operatorLabel` ('Addition'…) must stay English **as a key**: it is a
  stable lookup key for `SkillInfo.fromLabel` and `nq.skill.label`. Do not
  translate the stored value; translate only at the display site.

---

## 3. Leak table — Chrome literals (hard-coded UI strings)

| # | File | Line(s) | English string | Class | Fix |
|---|------|---------|----------------|-------|-----|
| C1 | `lib/core/widgets/sound_toggle_button.dart` | 21 | `'Sound: On'` / `'Sound: Off'` | chrome / **missing-key** | Add `AppStrings.soundOn`/`soundOff` (or `soundToggle(bool)`); pass `context.l10n` in. Widget needs a `BuildContext`/param. |
| C2 | `lib/core/widgets/pet_round_moment.dart` | 32 | `'Buddy'` | chrome | Use `context.l10n.buddy` (EXISTS). |
| C3 | `lib/core/widgets/pet_round_moment.dart` | 66 | `'🎉 Buddy grew!'` | chrome / **missing-key** | Add `AppStrings.buddyGrew` → "🎉 Buddy grew!" / "🎉 החבר גדל!". |
| C4 | `lib/games/number_quest/screens/parent_screen.dart` | 28 | `'Progress'` (AppBar) | chrome | Use `context.l10n.progress` (EXISTS). |
| C5 | `parent_screen.dart` | 44 | `'Hero Level'` | chrome / **missing-key** | Add `nqHeroLevel`. |
| C6 | `parent_screen.dart` | 45 | `'Total Stars'` | chrome / **missing-key** | Add `nqTotalStars`. |
| C7 | `parent_screen.dart` | 46 | `'Day Streak'` | chrome | Reuse concept of `dayStreak`; add label-only `nqDayStreakLabel` (dayStreak() includes the number). |
| C8 | `parent_screen.dart` | 49 | `'Skills'` | chrome / **missing-key** | Add `nqSkills`. |
| C9 | `parent_screen.dart` | 68 | `'Tip for grown-ups'` | chrome / **missing-key** | Add `nqGrownupTip`. |
| C10 | `parent_screen.dart` | 116-118 | `'Keep playing a few quests …'` | chrome / **missing-key** | Add `nqTipDefault`. |
| C11 | `parent_screen.dart` | 119-120 | `'Right now <skill> could use the most practice. …'` | chrome / **missing-key** | Add `nqTipWeakest(String skill)`; skill name must come from localized `nq.skill.label`, not `skill.label`. |
| C12 | `parent_screen.dart` | 174-176 | `'No questions yet'` / `'<c> / <t> correct'` | chrome | Add `nqNoQuestionsYet`; reuse `correctOfTotal` (EXISTS) for the second. |
| C13 | `lib/games/number_quest/screens/settings_screen.dart` | 112-114 | `'⭐ <n> stars   🪙 <n> coins   LV <n>'` | chrome / **missing-key** | Localize the words; keep digits/emoji. Add `nqStatsLine(...)` or compose from `stars`/`coins`/`levelAbbrev`. |
| C14 | `settings_screen.dart` | 145 | `'Reset all progress?'` | chrome / **missing-key** | Add `resetConfirmTitle`. |
| C15 | `settings_screen.dart` | 147-149 | `'This erases stars, XP, coins, avatars and awards across all games. This cannot be undone.'` | chrome / **missing-key** | Add `resetConfirmBody`. |
| C16 | `settings_screen.dart` | 155 | `'Cancel'` | chrome / **missing-key** | Add `cancel`. |
| C17 | `settings_screen.dart` | 163 | `'Reset'` | chrome / **missing-key** | Add `reset` (short). |
| C18 | `lib/games/word_wizard/services/word_generator.dart` | 115,164,201 | EN-branch prompts `'Which word is this?'` / `'Pick the missing letter'` / `'Which spelling is correct?'` | NOT a leak in `he` | These only run when `lang==en`. Hebrew branch (`_namePictureHe` etc.) uses Hebrew. Leave; see §6 note. |

Admin screen literals (`admin_screen.dart` lines 56-66 reset dialog,
153-175 shortcut labels, 180-213 warning banner/section labels) are a **hidden
dev-only tool**; `adminTitle`/`resetEverything` are intentionally English in BOTH
languages (see `HeStrings` lines 786-788). **Recommendation:** low priority /
leave as-is by design, OR localize only the user-reachable confirm dialog. Flag
to user; not counted as a user-facing leak.

---

## 4. Leak table — Game-screen HEADERS (data shown raw instead of via l10n/catalog)

All CONFIRMED. Pattern: header builds `'<emoji> <level.title>'` and
`'<emoji> <guardian/boss.name>'` from raw model getters. The matching Hebrew
already exists (shown correctly on the trail screens). Fix each to use the same
localized getters the trail screen uses, plus a `*.guardian.name`/`*.boss.name`
catalog lookup for the boss/guardian name.

| # | File | Line | Raw expression | Fix |
|---|------|------|----------------|-----|
| H1 | `number_quest/screens/game_screen.dart` | 243 | `level.title` (3 worlds) | Use `isBoss ? context.l10n.bossUpper : context.l10n.levelN(level.number)` for ALL levels, not just campaign. Remove the `isCampaign` gate. |
| H2 | `game_screen.dart` | 239-240 | `level.boss.name` (3 worlds) | Always `context.tr('nq.boss.name', level.bossId, level.boss.name)` (catalog has easy/intermediate/expert/times). |
| H3 | `game_screen.dart` | 487 (`_QuestionCard`) | `problem.operatorLabel.toUpperCase()` (3 worlds) | Always resolve `context.tr('nq.skill.label', SkillInfo.fromLabel(op).name, op)` then uppercase. Remove the `labelOverride==null` fallback to raw. **This is leak #4's root fix.** |
| H4 | `shape_safari/screens/safari_game_screen.dart` | 171 | `widget.level.title` | Add+use `s.guardian`/`s.stopN(number)` (both EXIST) like the trail screen does. |
| H5 | `safari_game_screen.dart` | 170 | `widget.level.guardian.name` | Add catalog key `ss.guardian.name` (EXISTS!) → `context.tr('ss.guardian.name', habitat.name, guardian.name)`. |
| H6 | `safari_result_screen.dart` | 165 | `level.guardian.name` in `safariFriendBanner` | Same `ss.guardian.name` lookup before passing to the banner. |
| H7 | `clock_hero/screens/clock_game_screen.dart` | 184 | `widget.level.title` | Use `s.guardian`/`s.stopN(number)` (EXIST). |
| H8 | `clock_game_screen.dart` | 183 | `widget.level.guardian.name` | `context.tr('ch.guardian.name', world.name, guardian.name)` (EXISTS). |
| H9 | `money_math/screens/money_game_screen.dart` | 153-154 | `level.title` + `guardian.name` | `s.guardian`/`s.stopN`; `context.tr('mm.guardian.name', world.name, guardian.name)` (EXISTS). |
| H10 | `memory_match/screens/memory_game_screen.dart` | 172-173 | `level.title` + `guardian.name` | `s.guardian`/`s.stopN`; `context.tr('mem.guardian.name', world.name, guardian.name)` (EXISTS). |
| H11 | `word_wizard/screens/wizard_game_screen.dart` | 165 | `widget.level.title` | Use `s.spellMaster`/`s.lessonN(number)` (EXIST) like the spellbook map does. |
| H12 | `wizard_game_screen.dart` | 164 | `widget.level.boss.name` | `context.tr('ww.boss.name', chapter.name, boss.name)` (EXISTS). |

**Underlying model getters that return raw English** (keep as English fallback,
but the DISPLAY sites above must stop reading them directly):
`number_quest/models/level.dart:54` `title => isBoss ? 'BOSS' : 'Level $number'`;
`shape_safari/models/safari_level.dart:28` `'Guardian'/'Stop $number'`;
`clock_hero/models/time_world.dart` `ClockLevel.title` `'Guardian'/'Stop $number'`;
`money_math/models/money_level.dart` (same shape — CONFIRMED via grep H9);
`memory_match/models/memory_level.dart` (same shape — grep H10);
`word_wizard/models/wizard_level.dart:104` `'Spell Master'/'Lesson $number'`.

---

## 5. Leak table — Clock Hero generator (NO Hebrew path exists)

CONFIRMED in `clock_hero/services/clock_generator.dart` and
`clock_hero/models/clock_time.dart`. These run in the service layer with no
`BuildContext`, so the fix needs the **Money Math pattern**: pass `AppLang lang`
into `ClockQuestionGenerator.forLevel(...)` (resolve `_lang` via `L10n.read` in
`ClockGameScreen.initState`, exactly like `MoneyGameScreen`/`WizardGameScreen`)
and branch the prompt + spoken-time formatting on language. The prompt string is
rendered directly as `Text(_q.prompt)` at `clock_game_screen.dart:200`.

| # | File | Line | English string | Class | Fix |
|---|------|------|----------------|-------|-----|
| K1 | `clock_generator.dart` | 86 | `'What time is it?'` | missing-key | Add `clockPromptRead`. |
| K2 | `clock_generator.dart` | 97 | `'Which clock shows <spoken>?'` | missing-key | Add `clockPromptFind(String spoken)`; `spoken` must be the Hebrew spoken form (see K6). |
| K3 | `clock_generator.dart` | 109 | `'Set the clock to <spoken>'` | missing-key | Add `clockPromptSet(String spoken)`. |
| K4 | `clock_generator.dart` | 121 | `'1 hour'` / `'<n> hours'` | missing-key | Add `clockHours(int n)` → he "שעה"/"<n> שעות". |
| K5 | `clock_generator.dart` | 124 | `"It's <spoken>. What time in <hourWord>?"` | missing-key | Add `clockPromptElapsed(String spoken, String hours)`. |
| K6 | `clock_time.dart` | 25-30 (`spoken`) | `"<h> o'clock"`, `'half past <h>'`, `'quarter past <h>'`, `'quarter to <h>'` | missing-key | Make a language-aware spoken formatter (e.g. `AppStrings.clockSpoken(hour, minute)` or a `lang` param). he: "השעה <h>", "<h> וחצי", "<h> ורבע", "רבע ל-<h>". |
| K7 | `clock_hero/models/time_world.dart` | 18-33 | `TimeWorld.label`/`subtitle` 'Morning'… / "O'clock times to wake up to." | NOT a leak at display | Shown via `ch.world.label/subtitle` catalog (EXISTS). Model getter is English fallback only — OK. |

Note: `ClockTime.label` ("3:30", numeric) is fine and already wrapped in an LTR
island; the readClock/elapsed answer CHOICES use `.label` (numeric) — OK.
| K8 | `clock_setter.dart` | 51,57 (rendered ~82) | `'Hour'` / `'Minute'` stepper captions | missing-key | CONFIRMED displayed via `_StepGroup`→`Text(label)`. Add `clockHour`/`clockMinute`; `ClockSetter` currently takes a raw `String label` per group, so pass `context.l10n` values from the game screen. |

---

## 6. Leak table — Shape Safari generator + shape names (NO catalog keys exist)

CONFIRMED in `shape_safari/services/question_generator.dart` and
`models/shape_kind.dart`. Same service-layer constraint as Clock Hero → pass
`AppLang lang` into `ShapeQuestionGenerator.forLevel` and branch, OR move prompt
building to the screen. Shape names (`ShapeKind.label`) are shown both as answer
choices (`ShapeChoice.text(s.label)`) and inside the `_find` prompt and the
wrong-answer feedback (`safari_game_screen.dart:106`), so they MUST be localized.

| # | File | Line | English string | Class | Fix |
|---|------|------|----------------|-------|-----|
| S1 | `shape_kind.dart` | 14-30 (`label`) | 'Circle','Oval','Triangle','Square','Rectangle','Pentagon','Hexagon','Star' | **missing-key (data)** | Add catalog domain `ss.shape.label` with 8 Hebrew values. Resolve at every display site via `context.tr('ss.shape.label', shape.name, shape.label)`. |
| S2 | `question_generator.dart` | 100 | `'What shape is this?'` | missing-key | Add `ssPromptIdentify`. |
| S3 | `question_generator.dart` | 115 | `'Which one is a <label>?'` | missing-key | Add `ssPromptFind(String shapeName)`; shapeName from localized `ss.shape.label`. |
| S4 | `question_generator.dart` | 141 | `'How many sides does this shape have?'` | missing-key | Add `ssPromptSides`. |
| S5 | `question_generator.dart` | 171 | `'What comes next?'` | missing-key | Add `ssPromptPattern`. |
| S6 | `safari_game_screen.dart` | 106 | `c.shape!.label` in wrong-answer feedback | data | Localize via `ss.shape.label` (same lookup) before `safariWrong(label)`. |

(`skillLabel: 'Identify'/'Find'/'Sides'/'Pattern'` — NOT displayed; not a leak.)

---

## 7. Word Wizard — words, prompts, and the VOICE/speaker (leak #2 + user request)

- **Hebrew word bank is correctly used in `he` mode.** CONFIRMED:
  `word_generator.dart:66` branches `if (lang == AppLang.he)` and `_pick` draws
  from `HebrewWordBank` (`word_bank.dart`). The screen resolves `_lang` once in
  `wizard_game_screen.dart:60` via `L10n.read`. So in Hebrew the questions,
  choices (niqqud display forms), prompts ("איזו מילה זאת?" etc.) are Hebrew.
- The English meaning line IS shown in `he` mode by design
  (`wizard_game_screen.dart:217` `_q.translation`) and the `matchTranslation`
  type shows English translations as the answer options — this is the
  user-requested translation feature, **not** a leak.
- **Caveat (ASSUMPTION):** `_lang` is captured once in `initState`; if the user
  flips EN⇄עב while a round is open, that round keeps the old language. Low risk
  (language is normally set before entering). Note only.

**VOICE / speaker removal (user explicitly asked to remove it):** CONFIRMED
sites in `wizard_game_screen.dart`:
- `_speakWord()` method, lines 75-85 (calls `FeedbackService.speak`).
- `_SpeakerButton` widget class, lines ~255-285.
- Render site inside the prompt panel, lines ~205-209
  (`_SpeakerButton(enabled: widget.state.soundOn, onTap: _speakWord)`).

Recommendation: remove the `_SpeakerButton` render + the `_speakWord` method +
the now-unused `WordQuestion.spokenWord` plumbing/`FeedbackService.speak` call
for this screen. The user's reasoning is sound: in `namePicture`/
`correctSpelling` the correct answer IS the spoken word, so the button leaks the
answer. (There is a `test/word_wizard_speaker_test.dart` that will need updating/
removing — flag to the coder.)

Also fix H11/H12 (header `level.title`/`boss.name`).

---

## 8. UI-consistency findings (recommendation only — no code)

### A. The streak 🔥 chip "doesn't look like the others"
CONFIRMED. In `game_hub_screen.dart` `_ProfileBar` (lines ~470-495) the streak is
a bespoke `Container` (white fill, 2.5px ink border, radius 14, 🔥 + count) that
is only shown `if (profile.dailyStreak > 0)`. Right next to it, `CoinPill`
(`core/widgets/coin_pill.dart`) and the HUD chips use their own, slightly
different container styling, and `_LangToggle` uses the accent fill. So the 🔥
chip is a one-off that doesn't match the coin pill. The same bespoke chip is
duplicated in `number_quest_home_screen.dart` `_Hud` (lines ~175-195).

**Recommendation:** extract a shared `StatChip`/`InfoPill` widget (icon/emoji +
value, matching `CoinPill`'s container: same fill, border width, radius, padding,
font) and render both the coin balance and the streak through it so they are
visually identical. Replace the two bespoke 🔥 containers with it. No behavior
change.

### B. "Level" indicator exists only in Number Quest
CONFIRMED. NQ shows a hero **Level/XP** via `XpBar(level:…, progress:…)` in
`number_quest_home_screen.dart` `_Hud` (line ~170) and "Hero Level" in
`parent_screen.dart`. The other 5 games have **no leveling system** (their state
stores track only stars + fastest time; XP/level lives in NQ's `GameState` and
the shared pet). So the NQ-only XP bar looks inconsistent across games.

**Recommendation (choose one):**
- **Option 1 (simplest, most consistent):** move the hero XP/level bar OFF the
  per-game NQ home and into the hub (or the pet screen) so no single game shows a
  unique indicator; each game home then shows only the shared HUD (avatar,
  streak chip from A, coins) + its own star total via `StarCoinHud`.
- **Option 2 (keep NQ flavor):** leave NQ's XP bar but give the other 5 games a
  neutral, equivalent HUD slot showing that game's **stars collected / total**
  (data already available in each state store) so every home has one progress
  indicator in the same spot. Recommend Option 1 for true consistency.

---

## 9. Consolidated list of NEW keys to author

Hebrew text below is a **suggested** starting point for the native reviewer; the
English is the required fallback. Author Hebrew for every one.

### New `AppStrings` chrome keys (add to abstract + `EnStrings` + `HeStrings`)
- `soundOn` / `soundOff` (or `soundToggle(bool on)`) — EN "Sound: On"/"Sound: Off".
- `buddyGrew` — EN "🎉 Buddy grew!".
- `nqHeroLevel` — EN "Hero Level".
- `nqTotalStars` — EN "Total Stars".
- `nqDayStreakLabel` — EN "Day Streak" (label only).
- `nqSkills` — EN "Skills".
- `nqGrownupTip` — EN "Tip for grown-ups".
- `nqTipDefault` — EN "Keep playing a few quests so we can spot which skills need the most practice.".
- `nqTipWeakest(String skill)` — EN "Right now <skill> could use the most practice. Try a few short sessions focused on that skill.".
- `nqNoQuestionsYet` — EN "No questions yet".
- `nqStatsLine(stars, coins, level)` (or reuse `stars`/`coins`/`levelAbbrev`) for the settings stat line.
- `resetConfirmTitle` — EN "Reset all progress?".
- `resetConfirmBody` — EN "This erases stars, XP, coins, avatars and awards across all games. This cannot be undone.".
- `cancel` — EN "Cancel".
- `reset` — EN "Reset".
- Masterly labels (`SkillStat.masteryLabel`, `skill.dart:69-76`): `masteryJustStarting`/`masteryMastered`/`masteryStrong`/`masteryPracticing`/`masteryNeedsPractice` — EN "Just starting"/"Mastered"/"Strong"/"Practicing"/"Needs practice". (Shown in `parent_screen.dart:155`.)
- Clock: `clockPromptRead`, `clockPromptFind(spoken)`, `clockPromptSet(spoken)`, `clockPromptElapsed(spoken, hours)`, `clockHours(int n)`, and a language-aware spoken-time formatter `clockSpoken(hour, minute)` (replaces `ClockTime.spoken` at the display/generator layer). Optionally `clockHour`/`clockMinute` for the setter captions (confirm).
- Shape: `ssPromptIdentify`, `ssPromptFind(shapeName)`, `ssPromptSides`, `ssPromptPattern`.

### New `LocalizedCatalog` data domains/keys
- `ss.shape.label` — 8 keys by `ShapeKind.name`: circle/oval/triangle/square/
  rectangle/pentagon/hexagon/star → עיגול/אליפסה/משולש/ריבוע/מלבן/מחומש/משושה/כוכב
  (suggested; native review required).

### Existing catalog/strings keys that are MISSING a display call (bypassed)
These need no new key — only wire the display site to the existing value:
- `nq.skill.label` (bypassed at `game_screen.dart` `_QuestionCard`).
- `nq.boss.name` (bypassed for the 3 worlds at `game_screen.dart:240`).
- `ss.guardian.name`, `ch.guardian.name`, `mm.guardian.name`, `mem.guardian.name`
  (bypassed at each game-screen header + safari result banner).
- `ww.boss.name` (bypassed at `wizard_game_screen.dart:164`).
- `AppStrings.bossUpper/levelN/stopN/guardian/spellMaster/lessonN` (exist; the
  game-screen headers read `level.title` instead).
- `AppStrings.buddy` (exists; `pet_round_moment.dart:32` hard-codes "Buddy").
- `AppStrings.progress` (exists; `parent_screen.dart:28` hard-codes "Progress").

---

## 10. Decisions the user should confirm

1. **Game "logo" split-text** on each home (`'NUMBER'/'QUEST'`, `'SHAPE'/'SAFARI'`,
   `'CLOCK'/'HERO'`, `'MEMORY'/'MATCH'`, `'MONEY'/'MATH'`, `'WORD'/'WIZARD'`)
   — `*_home_screen.dart` lines ~180-234 (CONFIRMED). This is the "game names in
   English" the user noticed inside a game. **Options:** (a) replace each with the
   localized `game.title` from the catalog (loses the stylized 2-line logo look),
   or (b) author a Hebrew 2-line logo per game as new keys. Recommend (a) for
   consistency with the hub cards. **Confirm with user before changing**, as it
   changes the visual logo.
2. **Admin screen** English (hidden dev tool) — leave as-is (recommended) or
   localize only the confirm dialog?
3. **UI-consistency §8** — pick Option 1 vs 2 for the level indicator.

---

## 11. Confidence notes

- CONFIRMED (file+line read): all of §3 except C13 line exactness; all §4; all §5
  except K7-setter-caption; all §6; §7 speaker sites; §8 A/B render sites; §10.1.
- CONFIRMED additionally: `clock_setter.dart` 'Hour'/'Minute' ARE rendered as
  stepper captions; all six model `title` getters read (`level.dart:30`,
  `safari_level.dart:29`, `time_world.dart:116`, `money_level.dart:101`,
  `memory_level.dart:111`, `wizard_level.dart:104`).
- ASSUMPTION (inference only): Word Wizard mid-round language flip edge case;
  exact Hebrew wording (native review required for every suggested Hebrew string);
  the clock `clockHour`/`clockMinute` key naming.
