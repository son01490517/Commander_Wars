# 1A-08 — Load CO sprites only when needed

- **Status:** Todo
- **Difficulty:** hard
- **Depends on:** 1A-06 (and the lazy-loading API from 1A-04)
- **Context budget:** ~90k tokens

## Goal
In handheld builds, `COSpriteManager` keeps only small CO images resident (faces and icons shown in selection
lists). Large CO images (portraits about 208x352, and other big variants) load on first use, and are unloaded
when the player returns to the main menu. During a match, only the COs of the players in that match should end
up loaded.

## Facts
- `resources/images/co/res.xml`: one `<set>` and 858 `<image>` entries. Army folders are
  `co/{ac,bd,bg,bh,bm,dm,ge,gs,ma,os,pf,ti,yc}/`.
- `COSpriteManager` ctor: `resource_management/cospritemanager.cpp:10-18`. Recolored variants are created
  lazily in `COSpriteManager::loadResAnim` (`cospritemanager.cpp:63-180`) and `CO::loadResAnim`
  (`game/co.cpp:2247-2307`). Keep that logic working with lazily loaded base images.
- `removeRessource` exists (`cospritemanager.cpp:182`) but has no callers.
- Match start hooks: `menue/mapselectionmapsmenue.cpp:382-400`, `menue/campaignmenu.cpp:515`,
  `menue/mainwindow.cpp:347` (load save). Main menu entry: `menue/mainwindow.cpp:58`
  (`Mainwindow` ctor), a good place to unload per-match resources.
- The inventory (`docs/tasks/data/resource-inventory.csv`, class `per_co`) lists ids and MB.

## Design
- Use the 1A-04 lazy API for `COSpriteManager`. Decide "small vs large" by decoded size (for example
  ≤ 64x64 stays eager), not by name guessing. Write the rule in a comment.
- Add `COSpriteManager::unloadLargeSprites()` (handheld only) and call it from the `Mainwindow` ctor.
- Recolor caches built by `loadResAnim` for COs not in the current match must be dropped on the same unload.

## Read list
- `resource_management/cospritemanager.cpp/.h`
- `game/co.cpp:2240-2320`, `game/co.h` around `loadResAnim`
- Lazy API comment in `3rd_party/oxygine-framework/oxygine/res/Resources.h`
- `menue/mainwindow.cpp:50-70`
- `docs/tasks/data/resource-inventory-summary.md`, `grep per_co docs/tasks/data/resource-inventory.csv | head -60`

## Files to modify
`resource_management/cospritemanager.cpp/.h`, `menue/mainwindow.cpp` (one guarded call), and `game/co.cpp`
only if the recolor path needs a guard.

## Out of scope
Unit/building sprites (1A-09), CO selection UI layout.

## Acceptance criteria
1. Handheld build OK. The RAM run reaches the game, and `max_day_reached` ≥ 3 (COs are used during the match).
2. `peak_rss_mb` drops versus 1A-07 by at least 50% of the `per_co` MB in the inventory summary. Write the expected number in the Result.
3. No `Critical`/`Fatal` lines about missing CO resources in `markers.log`.
4. Desktop build still compiles: `.handheld/receipts/1A-08-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-08-build
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-08-build/build.log
tools/handheld/measure-ram.sh -l 1A-08-ram
tools/handheld/build-desktop-check.sh 1A-08-desktop
tools/jev-review.sh 1A-08
```

## Result

## Handoff notes
