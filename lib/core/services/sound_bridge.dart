// Plays synthesized sound effects. On web it calls the JS `window.MAAudio`
// synthesizer defined in web/index.html; on other platforms it no-ops.
//
// Conditional import picks the right implementation at compile time.
import 'sound_bridge_stub.dart'
    if (dart.library.js_interop) 'sound_bridge_web.dart' as impl;

/// Simple façade over the platform sound implementation.
class SoundBridge {
  /// Global on/off, kept in sync with the settings toggle by [GameState].
  /// Lets low-level widgets (like buttons) play a click without threading
  /// state through every constructor.
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

  /// Speaks [text] aloud with the browser's text-to-speech. Respects the same
  /// [enabled] toggle as sound effects; a no-op where speech is unavailable.
  static void speak(String text) {
    if (!enabled) return;
    impl.speak(text);
  }

  /// Stops any in-progress speech. Safe no-op where speech is unavailable.
  static void cancelSpeech() => impl.cancelSpeech();
}
