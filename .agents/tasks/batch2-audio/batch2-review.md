# Tap-to-speak word audio in Word Wizard (SpeechSynthesis)

Batch 2 adds browser text-to-speech so pre-readers can hear the Word Wizard target word read aloud. The approach extends the existing `SoundBridge` conditional-import split with a parallel speech path (`speak`/`cancelSpeech`), threads it through `FeedbackService.speak`, and gives `WordQuestion` a new optional `word` field plus a `spokenWord` accessor so the full correct word is available even for missing-letter questions whose `choices` are single letters. A big comic-style speaker button sits under the emoji on the gameplay screen and reads the correct answer word. The JS layer guards `maSpeak`/`maCancelSpeech` the same defensive way as `maPlaySound`.

Watch for: nothing blocking. The implementation is tight — the stub/web split stays clean (no js_interop leak), all three question types resolve to the correct full word, and the button correctly disables when sound is off. The one judgment call (greyed-but-visible vs hidden when sound is off) was made explicitly and consistently (confirmed).

**Verdict**: APPROVED

## High-level view

The JS entry points `maSpeak` and `maCancelSpeech` land in `web/index.html` next to the existing `maPlaySound`, wrapped in the same `typeof`/`try-catch` guards so they are harmless no-ops wherever `speechSynthesis` or `SpeechSynthesisUtterance` is unavailable, with child-friendly tuning (rate 0.9, pitch 1.1, en-US) and an upfront `cancel()` so rapid taps don't stack.

The Dart side mirrors the proven `SoundBridge` conditional-import pattern. The import now carries an `as impl` alias, both `sound_bridge_stub.dart` and `sound_bridge_web.dart` gain matching top-level `speak`/`cancelSpeech` functions (stub no-ops; web calls the `@JS` externals), `SoundBridge.speak` early-returns on `!enabled`, and `FeedbackService.speak` gates on `enabled` before delegating. The non-web build stays clean because js_interop lives only in the web file.

The correct-word problem is solved at the model and generator level: `WordQuestion` gains an optional `word` plus a `spokenWord` getter that returns `word` or falls back to `choices[correctIndex]`. The generator sets `word` on all three types — `answer.word` (namePicture), the full unmasked `word` (missingLetter), and `correct` (correctSpelling) — so the spoken word is never a distractor and never the masked display.

The speaker button is a 64×64 comic-styled `GestureDetector` (ink border, hard offset shadow, `Icons.volume_up_rounded`) placed under the emoji. When sound is off it stays visible but greyed and inert for stable layout — a documented, intentional choice. A new widget test asserts the button renders and taps without throwing on a 430×900 surface.

<details>
<summary>Issues (0)</summary>

No blocking or actionable findings. All five criteria verified behaviorally.

</details>

<details>
<summary>Details</summary>

### Criterion 1 — JS `maSpeak`/`maCancelSpeech` guarding

`web/index.html` adds `window.maSpeak(text)` guarded identically to `maPlaySound`: it returns early if `speechSynthesis` or `SpeechSynthesisUtterance` is undefined, and if `text` is not a non-empty string, all inside a `try/catch` that swallows errors as a no-op. It calls `speechSynthesis.cancel()` before speaking so taps don't pile up, and tunes the utterance for kids (`rate = 0.9`, `pitch = 1.1`, `lang = 'en-US'`). A companion `window.maCancelSpeech()` is added, also guarded. This matches the requested behavior exactly (confirmed).

### Criterion 2 — Dart speech path mirrors the SoundBridge split

The conditional import gains `as impl` so the façade calls `impl.playSound` / `impl.speak` / `impl.cancelSpeech`. Both implementation files expose matching top-level functions: `sound_bridge_stub.dart` has `void speak(String)` and `void cancelSpeech()` as no-ops; `sound_bridge_web.dart` adds `@JS('maSpeak')`/`@JS('maCancelSpeech')` externals and wraps them. `SoundBridge.speak` early-returns on `!enabled` before delegating; `FeedbackService.speak` also gates on `enabled`. Because `dart:js_interop` is imported only in the web file, the non-web (stub) build has no js_interop reference and keeps compiling. The commit records `flutter build web -> Built build\web` and `flutter test -> All tests passed`, which exercises the stub path (confirmed).

Minor note, non-blocking: `SoundBridge.cancelSpeech()` is intentionally not gated on `enabled` (stopping speech should work regardless of the toggle), which is the correct call.

### Criterion 3 — speaks the correct target word for all three types

`WordQuestion.spokenWord` returns `word ?? choices[correctIndex]` with a bounds guard. The generator now sets `word` on every type:
- `_namePicture`: `word: answer.word` — the full word (confirmed).
- `_missingLetter`: `word: word`, where `word = entry.word` is the full unmasked word, not the masked `shown` string and not the single-letter `choices` (confirmed — this was the specific risk called out).
- `_correctSpelling`: `word: correct = entry.word`, the correctly spelled word, never a misspelled distractor (confirmed).

Since `word` is always populated, `spokenWord` never falls back to `choices` in practice, so even if `choices[correctIndex]` were a letter it would not be spoken. The fallback itself still points at `correctIndex`, never a distractor (confirmed).

### Criterion 4 — big tappable comic button, respects toggle / availability

`_SpeakerButton` is a 64×64 `GestureDetector` with `AppTheme.comicBorder`, `AppTheme.comicShadow(offset: 4)`, rounded corners, and `Icons.volume_up_rounded` at size 36 — a clearly tappable comic control placed directly under the emoji and above the prompt. When `enabled` is false, `onTap` is `null` and the fill is grey, so it is present-but-inert. The coder explicitly documented this choice ("button stays VISIBLE but greyed/inert for stable layout (not hidden)") and the code matches it (confirmed). Availability is handled downstream: `_speakWord` routes through `FeedbackService.speak`, which no-ops when sound is off, and the JS layer no-ops when SpeechSynthesis is missing.

### Criterion 5 — hygiene constraints

No new pub dependencies (changes are confined to existing files plus one new test; no pubspec change in the diff). No `MediaQuery.size` width sizing is introduced — the button uses fixed 64×64 dimensions. Extension-defining files are not newly required here; the button relies on static `AppTheme` members (`sky`, `comicBorder`, `comicShadow`), all present in `core/theme/app_theme.dart`, and the file is already imported. `const` is used where reasonable (`_SpeakerButton` constructor, the `Icon`, `SizedBox`) (confirmed).

### Test coverage

`test/word_wizard_speaker_test.dart` sets a 430×900 phone surface, builds `WizardGameScreen` with a loaded profile/state and the first level, finds exactly one `Icons.volume_up_rounded`, taps it, and asserts no exception. This exercises the full tap→`_speakWord`→`FeedbackService.speak`→`SoundBridge.speak`→stub plumbing under test.

Not tested: the actual spoken-word correctness per question type (that the right word reaches `maSpeak`) is verified by code inspection rather than a unit test on `spokenWord`; and the greyed/inert state when `soundOn` is false is not asserted. Neither gap is blocking given the generator/accessor logic is straightforward and directly inspected.

</details>

<details>
<summary>File map</summary>

- `web/index.html` — added guarded `maSpeak`/`maCancelSpeech`.
- `lib/core/services/sound_bridge.dart` — `as impl` alias; `speak`/`cancelSpeech` façade methods.
- `lib/core/services/sound_bridge_stub.dart` — no-op `speak`/`cancelSpeech`.
- `lib/core/services/sound_bridge_web.dart` — `@JS` externals + wrappers for speech.
- `lib/core/services/feedback_service.dart` — `speak(text)` gated on `enabled`.
- `lib/games/word_wizard/models/word_question.dart` — optional `word` field + `spokenWord` getter.
- `lib/games/word_wizard/services/word_generator.dart` — sets `word` on all three question types.
- `lib/games/word_wizard/screens/wizard_game_screen.dart` — `_speakWord` + `_SpeakerButton`.
- `test/word_wizard_speaker_test.dart` — new widget test for the speaker button.

Full diff: `git -C <worktree> diff 57d5645 8e5ac87`

</details>
