# 1A-04 — Load menu backgrounds on demand

- **Status:** Todo
- **Difficulty:** hard
- **Depends on:** 1A-03
- **Context budget:** ~80k tokens

## Goal
In handheld builds, `BackgroundManager` must not decode and upload all 81 entries of
`resources/images/backgrounds/res.xml` at startup. Only the background that is actually displayed gets
loaded, and the previous one is freed when a different background is shown.

## Why (measured)
- `res.xml` has 16 PNGs (lines 5-20), 43 `mainmenu_N.jpg` (21-63) and 22 `gamemenu_N.jpg` (64-85). The JPGs
  are 1536x864, 5.3 MB each when decoded, ≈ 345 MB total, but one is visible at a time.
- Eager load: `3rd_party/oxygine-framework/oxygine/core/renderer.cpp:85` →
  `resource_management/ressourcemanagement.h:141-152` → `Resources::loadXML`
  (`oxygine/res/Resources.cpp:108-190`) → `ResAtlasGeneric::loadAtlas` (`ResAtlasGeneric.cpp:94-239`).

## Design
- Build lazy loading as a **reusable, opt-in feature** of the oxygine resource layer (`Resources` /
  `ResAtlasGeneric`), because cards 1A-07, 1A-08 and 1A-09 reuse it for other managers. Suggested API:
  `Resources::setLazyLoading(bool)` before `loadXML`, plus `Resources::unloadResAnim(id)` and
  `Resources::setMaxResident(int)` (LRU). Desktop never enables it.
- Under `HANDHELD_BUILD`, `BackgroundManager` registers its entries **without** decoding them (keep the
  id → file path mapping). Decode and upload on the first `getResAnim(id)` for that id.
- Keep at most **2** decoded backgrounds (current plus the one being faded in). Free the oldest with the
  same mechanism `Resources::free` uses (`Resources.cpp:90-95`), but per entry.
- The 16 small PNG entries (lines 5-20) may stay eagerly loaded.
- Callers that choose a background: `ui_reader/createdgui.cpp:200-269`,
  `resources/scripts/general/backgroundSelector.js:76-160`, `objects/loadingscreen.cpp:34-49`,
  `menue/gamemenue.cpp:1582`. They should not need changes if `getResAnim` loads lazily. Verify this.
- The loading screen is shown before `res.xml` is registered (`coreengine/mainapp.cpp:221-234`). Keep the
  current null-check behavior.

## Read list
- `resource_management/backgroundmanager.cpp/.h` (small)
- `resource_management/ressourcemanagement.h:120-240`
- `3rd_party/oxygine-framework/oxygine/res/Resources.cpp:80-200`, `Resources.h`
- `3rd_party/oxygine-framework/oxygine/res/ResAtlasGeneric.cpp:40-240`, `ResAtlas.cpp:15-70`
- `3rd_party/oxygine-framework/oxygine/core/renderer.cpp:70-90`
- `ui_reader/createdgui.cpp:195-270`, `objects/loadingscreen.cpp:25-60`
- `resources/images/backgrounds/res.xml` (head 25 lines)

## Files to modify
`resource_management/backgroundmanager.cpp/.h`, `3rd_party/oxygine-framework/oxygine/res/Resources.cpp/.h`,
`ResAtlasGeneric.cpp/.h`, `ResAtlas.cpp/.h` (new behavior only when lazy loading is enabled).
Document the new API in a short comment block in `Resources.h`; later cards rely on it.

## Out of scope
Changing the background images (1A-05), other managers.

## Acceptance criteria
1. Handheld build OK. The RAM run reaches the game.
2. `menu_rss_mb` drops by at least 150 MB compared with the 1A-03 result. (Each JPG costs ≈ 5.3 MB of GPU memory after 1A-03, so the expected drop is ≈ 330 MB.)
3. A 40 s `-M` (menu-only) run: `.handheld/receipts/1A-04-menu/observation.txt` (written by you after looking at
   `shot.png`) states that a painted background is visible behind the main menu buttons.
4. Desktop build still compiles: `.handheld/receipts/1A-04-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-04-build
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-04-build/build.log
tools/handheld/measure-ram.sh -l 1A-04-ram
tools/handheld/measure-ram.sh -l 1A-04-menu -s 40 -M
# write what shot.png of 1A-04-menu shows into .handheld/receipts/1A-04-menu/observation.txt
tools/handheld/build-desktop-check.sh 1A-04-desktop
tools/jev-review.sh 1A-04
```

## Result

## Handoff notes
