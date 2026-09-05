// Plays synthesized sound effects. On web it calls the JS `window.MAAudio`
// synthesizer defined in web/index.html; on other platforms it no-ops.
//
// Conditional import picks the right implementation at compile time.
import 'sound_bridge_stub.dart'
    if (dart.library.js_interop) 'sound_bridge_web.dart';

/// Simple façade over the platform sound implementation.
class SoundBridge {
  /// Global on/off, kept in sync with the settings toggle by [GameState].
  /// Lets low-level widgets (like buttons) play a click without threading
  /// state through every constructor.
  static bool enabled = true;

  static void _play(String name) {
    if (!enabled) return;
    playSound(name);
  }

  static void click() => _play('click');
  static void correct() => _play('correct');
  static void wrong() => _play('wrong');
  static void coin() => _play('coin');
  static void levelUp() => _play('levelup');
  static void victory() => _play('victory');
}
