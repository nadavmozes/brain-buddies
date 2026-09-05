---
inclusion: always
---

# Tech Stack & Build Commands

## Stack

- **Flutter** (Dart SDK 3.0+), package name `brain_buddies`.
- Dependencies: `shared_preferences` (persistence), `google_fonts` (Baloo 2).
- No audio packages: sound effects are **synthesized in JS** (Web Audio) via
  `web/index.html` and called through `lib/core/services/sound_bridge*.dart`.

## This machine (Windows) — important

- Flutter is installed at `%USERPROFILE%\flutter`. It is on PATH, but when running
  from tooling always call it explicitly:
  `& "$env:USERPROFILE\flutter\bin\flutter.bat" <cmd>`
- Shell is PowerShell. Use `;` not `&&`. Use `$env:VAR` not `%VAR%`.

## Build / run / test

```powershell
# Build the web app (primary verification step on this machine)
& "$env:USERPROFILE\flutter\bin\flutter.bat" build web

# Run tests
& "$env:USERPROFILE\flutter\bin\flutter.bat" test

# Serve the built app locally (also prints the LAN IP URL for phones)
node demo\server.js build\web    # http://localhost:8000
```

## Verification policy (do this every change)

1. `flutter build web` MUST succeed — this is the real compiler check.
2. `flutter test` MUST pass.
3. When filtering build output, keep the `Built` line and any `Error`/`.dart:`
   lines. A trailing `Exit Code: 1` from `Select-String` (no matches after the
   Built line) is NOT a build failure — confirm by the presence of `Built build\web`.

## Known environment quirks

- `flutter analyze` CRASHES on this project because the path contains non-ASCII
  (Hebrew) characters — the analysis server's URI parser fails. Building, testing,
  and running are unaffected. Do NOT rely on `analyze`; rely on `build web`.
- The `smart_relocate` tool does NOT rewrite Dart relative imports here (analysis
  server is down). After moving files, fix imports manually and confirm with a build.
