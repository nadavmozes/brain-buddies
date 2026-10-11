// Reloads the running app so a full admin "reset everything" starts the hub
// from a clean slate. Only the web build can actually reload the page; every
// other platform (and `flutter test`) uses the stub no-op.
//
// Conditional import picks the right implementation at compile time, mirroring
// the `sound_bridge.dart` pattern.
import 'admin_reload_stub.dart'
    if (dart.library.js_interop) 'admin_reload_web.dart' as impl;

/// Reloads the whole app. On web this reloads the browser page; everywhere
/// else (including under `flutter test`) it is a no-op so the build compiles
/// and tests never trigger a real reload.
void reloadApp() => impl.reloadApp();
