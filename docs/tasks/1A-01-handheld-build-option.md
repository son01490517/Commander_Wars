# 1A-01 — HANDHELD_BUILD option and handheld defaults

- **Status:** Todo
- **Difficulty:** medium
- **Depends on:** 1A-00
- **Context budget:** ~50k tokens

## Goal
Add a CMake option `HANDHELD_BUILD` (default OFF) and make the handheld build use these defaults:
1. `DEFAULTAIPIPE` forced OFF and `DEPLOY_RESOURCES_AS_FOLDER` forced ON when `HANDHELD_BUILD=ON`.
2. Compile definition `HANDHELD_BUILD` available to all C++ code.
3. Settings default values under `#ifdef HANDHELD_BUILD`: BattleAnimationMode = `None`, CaptureAnimation = `false`.
4. MSAA off: `newFormat.setSamples(2)` → no multisampling under `HANDHELD_BUILD`.
5. Initial map zoom 1x instead of 2x under `HANDHELD_BUILD`. Today `GameMap::loadMapData` calls `setZoom(1)`,
   which multiplies the scale by `ZoomModifier` (default 2.0), so maps start at 2x.
6. A JS-visible getter `settings.getHandheldBuild()` (Q_INVOKABLE, returns true only in handheld builds) for later cards.

## Why
All later cards depend on one switch that keeps desktop builds unchanged.

## Read list
- `CMakeLists.txt:33-46` (options), `CMakeLists.txt:159-195`
- `CommanderWarsSources.cmake:200-235` (option → `add_definitions` pattern, e.g. `-DDEFAULTAIPIPE` at 226-234)
- `coreengine/settings.cpp:1440-1460`, `1525-1550` (default-value table: BattleAnimationMode 1530, CaptureAnimation 1544)
- `coreengine/settings.h:410-420` (Q_INVOKABLE getter style, e.g. `getSmallScreenDevice`)
- `3rd_party/oxygine-framework/oxygine/core/gamewindow.cpp:30-50` (`setSamples(2)` at line 38)
- `game/gamemap.cpp:125-132` (`setZoom(1)`), `game/gamemap.cpp:1298-1325`

## Files to modify
`CMakeLists.txt`, `CommanderWarsSources.cmake`, `coreengine/settings.cpp`, `coreengine/settings.h`,
`3rd_party/oxygine-framework/oxygine/core/gamewindow.cpp`, `game/gamemap.cpp`,
`tools/handheld/build-linux.sh` (add `-DHANDHELD_BUILD=ON` to the default cmake call).

## Out of scope
UI layout, gamepad, resource loading, the Multiplayer button (1A-02).

## Acceptance criteria
1. A desktop configure (`HANDHELD_BUILD` unset) compiles exactly as before. Every new behavior is inside `#ifdef HANDHELD_BUILD` or the CMake `if(HANDHELD_BUILD)` block.
2. `tools/handheld/build-linux.sh` builds with `HANDHELD_BUILD=ON` and prints `BUILD_OK`. `configure.log` shows the handheld message.
3. The RAM run reaches the game. `.handheld/receipts/1A-01-ram/observation.txt` (written by you after looking at
   `shot.png`) states how many map tiles are visible horizontally; 1x means about 20 (32 px tiles), 2x about 10.
4. `peak_rss_mb` is not higher than the 1A-00 baseline by more than 20 MB.
5. Desktop build still compiles: `.handheld/receipts/1A-01-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-01-build
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-01-build/build.log
docker run --rm -v cw-build:/build cw-linux-arm64 grep -i handheld /build/configure.log | tee .handheld/receipts/1A-01-build/configure.txt
tools/handheld/measure-ram.sh -l 1A-01-ram
tools/handheld/build-desktop-check.sh 1A-01-desktop
tools/jev-review.sh 1A-01
```

## Result
(fill in: peak_rss_mb, menu_rss_mb)

## Handoff notes
(only if blocked)
