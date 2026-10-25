# 1A-02 — Hide Multiplayer button on handheld

- **Status:** Todo
- **Difficulty:** easy
- **Depends on:** 1A-01
- **Context budget:** ~30k tokens

## Goal
In handheld builds, the main menu shows no Multiplayer button, and the buttons below it move up so there is no gap.
The network code stays compiled and untouched, because phase 2 reuses it for online AI.

## Read list
- `resources/ui/menu/mainmenu.xml` (whole file, short; Multiplayer button at lines 25-32)
- The JS that positions the buttons: `MainMenu.getButtonY` (search `resources/ui/menu/` for `getButtonY`)
- `ui_reader/uifactory.cpp`: only the part that parses `<enabled>` and any `<visible>`-like element (search for `"enabled"`)
- `coreengine/settings.h`: `getHandheldBuild` added by 1A-01

## Files to modify
`resources/ui/menu/mainmenu.xml`, the JS file containing `getButtonY` (only if needed),
`ui_reader/uifactory.cpp` (only if a visibility element must be added).

## Out of scope
Removing network sources, changing `Mainwindow::enterMultiplayer`, any other menu.

## Acceptance criteria
1. With `settings.getHandheldBuild()` true, the Multiplayer button is not created or not visible, and the remaining buttons have no gap.
2. Desktop main menu is unchanged.
3. Build OK. The 640x480 main-menu screenshot from `measure-ram.sh -M` shows no Multiplayer button.
4. Desktop build still compiles: `.handheld/receipts/1A-02-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-02-build
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-02-build/build.log
tools/handheld/measure-ram.sh -l 1A-02-menu -s 40 -M     # stays in the main menu, takes shot.png
# look at .handheld/receipts/1A-02-menu/shot.png and write what you see (button list) to
# .handheld/receipts/1A-02-menu/observation.txt
tools/handheld/build-desktop-check.sh 1A-02-desktop
tools/jev-review.sh 1A-02
```
Note: this run is menu-only (`menu_only=true`), so `reached_game=false` is expected and valid for this card.

## Result

## Handoff notes
