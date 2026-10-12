// Web implementation: calls the global `window.maPlaySound(name)` defined in
// web/index.html, which dispatches to the Web Audio synthesizer.
import 'dart:js_interop';

@JS('maPlaySound')
external void _maPlaySound(JSString name);

@JS('maSpeak')
external void _maSpeak(JSString text, JSString lang);

@JS('maCancelSpeech')
external void _maCancelSpeech();

void playSound(String name) {
  _maPlaySound(name.toJS);
}

void speak(String text, {String lang = 'en-US'}) {
  _maSpeak(text.toJS, lang.toJS);
}

void cancelSpeech() {
  _maCancelSpeech();
}
