// Non-web implementation: no synthesized audio available, so do nothing.
// (Native platforms still get haptics + system sounds via FeedbackService.)
void playSound(String name) {}

// No text-to-speech off the web, so these are no-ops.
void speak(String text, {String lang = 'en-US'}) {}

void cancelSpeech() {}
