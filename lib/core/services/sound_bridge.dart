// Plays synthesized sound effects. On web it calls the JS `window.MAAudio`
// synthesizer defined in web/index.html; on other platforms it no-ops.
//
// Conditional import picks the right implementation at compile time.
import 'sound_bridge_stub.dart'
    if (dart.library.js_interop) 'sound_bridge_web.dart' as impl;

/// Simple façade over the platform sound implementation.
class SoundBridge {
  /// Global on/off for all sound (effects + speech). Lets low-level widgets
  /// (like buttons) play a click without threading state through every
  /// constructor.
  ///
  /// NOTE ON SOURCES OF TRUTH (known limitation): this one flag is written
  /// from several independent `sound_on` booleans — [PlayerProfile.soundOn]
  /// (`profile_sound`) and each per-game store's own `*_sound` key (see
  /// [GameProgressStore] and Number Quest's `GameState`). Each store sets
  /// `SoundBridge.enabled` from its own value on load and on toggle, so the
  /// effective state is whichever store loaded or toggled LAST ("last writer
  /// wins"). In practice this is fine because toggling the setting in any
  /// screen immediately updates this flag, but there is no single hub-wide
  /// source of truth. FUTURE WORK: unify to a single hub sound setting.
  static bool enabled = true;

  static void _play(String name) {
    if (!enabled) return;
    impl.playSound(name);
  }

  static void click() => _play('click');
  static void correct() => _play('correct');
  static void wrong() => _play('wrong');
  static void coin() => _play('coin');
  static void levelUp() => _play('levelup');
  static void victory() => _play('victory');

  /// Speaks [text] aloud with the browser's text-to-speech in the given BCP-47
  /// [lang] (e.g. 'en-US', 'he-IL'). Respects the same [enabled] toggle as
  /// sound effects; a no-op where speech is unavailable. A missing voice for
  /// [lang] is a silent no-op in the JS layer — never gate correctness on it.
  static void speak(String text, {String lang = 'en-US'}) {
    if (!enabled) return;
    impl.speak(text, lang: lang);
  }

  /// Stops any in-progress speech. Safe no-op where speech is unavailable.
  static void cancelSpeech() => impl.cancelSpeech();
}
