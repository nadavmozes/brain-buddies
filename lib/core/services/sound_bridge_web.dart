// Web implementation: calls the global `window.maPlaySound(name)` defined in
// web/index.html, which dispatches to the Web Audio synthesizer.
import 'dart:js_interop';

@JS('maPlaySound')
external void _maPlaySound(JSString name);

void playSound(String name) {
  _maPlaySound(name.toJS);
}
