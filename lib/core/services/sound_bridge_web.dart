// Web implementation: calls the global `window.maPlaySound(name)` defined in
// web/index.html, which dispatches to the Web Audio synthesizer.
import 'dart:js_interop';

@JS('maPlaySound')
external void _maPlaySound(JSString name);

@JS('maSpeak')
external void _maSpeak(JSString text);

@JS('maCancelSpeech')
external void _maCancelSpeech();

void playSound(String name) {
  _maPlaySound(name.toJS);
}

void speak(String text) {
  _maSpeak(text.toJS);
}

void cancelSpeech() {
  _maCancelSpeech();
}
