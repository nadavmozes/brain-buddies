// Web implementation: reloads the browser page via window.location.reload().
//
// Uses a small top-level `@JS` external (the same dart:js_interop style as
// sound_bridge_web.dart) rather than an `extension type`, which keeps it
// compatible with this project's enabled language features.
import 'dart:js_interop';

@JS('location.reload')
external void _reload();

void reloadApp() {
  _reload();
}
