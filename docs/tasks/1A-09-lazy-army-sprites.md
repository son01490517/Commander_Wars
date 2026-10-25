# 1A-09 — Load army-specific unit/building sprites only for armies in the match

- **Status:** Todo
- **Difficulty:** hard
- **Depends on:** 1A-08
- **Context budget:** ~90k tokens

## Goal
In handheld builds, sprites whose class in the inventory is `per_army` load on first use and are unloaded when
returning to the main menu, the same way 1A-08 handles CO sprites. Army-neutral sprites (`always`) stay eager.

## Facts
- Unit sprite ids are built in unit scripts, for example `resources/scripts/units/infantry.js:54-57`
  (`infantry+<armyName>+mask`, `infantry+<armyName>`; `armyName` comes from `Global.getArmyNameFromPlayerTable`).
- `Unit::loadSpriteV2` (`game/unit.cpp:264-297`) looks up `UnitSpriteManager`. Buildings:
  `resource_management/buildingspritemanager.cpp`. Terrain: `resource_management/terrainmanager.cpp`.
- Army of a player: `Player::getArmy()` (`game/player.cpp:584`), `Player::defineArmy()` (`player.cpp:2084-2089`).
- Unload hook from 1A-08: the `Mainwindow` ctor.

## Design
- Reuse the 1A-04 lazy API and the 1A-08 unload hook. Classify by the inventory CSV, not by guessing.
  Generate a small lookup table (for example `resources/handheld/lazy-ids.txt` or a compiled list) from the CSV
  with a script, so the decision is data-driven.
- Terrain stays eager unless the inventory shows large army-specific terrain sets.

## Read list
- `resource_management/unitspritemanager.cpp/.h`, `buildingspritemanager.cpp/.h`
- `game/unit.cpp:255-300`
- 1A-08 changes in `cospritemanager.cpp` (`git show <1A-08 commit> --stat` then the relevant hunks)
- `docs/tasks/data/resource-inventory-summary.md`, `grep per_army docs/tasks/data/resource-inventory.csv | head -60`

## Files to modify
`resource_management/unitspritemanager.cpp/.h`, `buildingspritemanager.cpp/.h`, the 1A-08 unload hook,
`tools/handheld/inventory/*` (lookup generator), and the generated lookup file.

## Out of scope
Terrain atlases (unless justified by the inventory), texture formats.

## Acceptance criteria
1. Handheld build OK. The RAM run reaches the game with `max_day_reached` ≥ 3.
2. `peak_rss_mb` drops versus 1A-08 by at least 50% of the `per_army` MB in the inventory summary.
3. No `Critical`/`Fatal` about missing unit or building resources in `markers.log`.
4. Desktop build still compiles: `.handheld/receipts/1A-09-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-09-build
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-09-build/build.log
tools/handheld/measure-ram.sh -l 1A-09-ram
tools/handheld/build-desktop-check.sh 1A-09-desktop
tools/jev-review.sh 1A-09
```

## Result

## Handoff notes
