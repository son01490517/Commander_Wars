# 1A-07 — Skip battle/capture animation resources when disabled

- **Status:** Todo
- **Difficulty:** hard
- **Depends on:** 1A-06 (and the lazy-loading API from 1A-04)
- **Context budget:** ~70k tokens

## Goal
In handheld builds with BattleAnimationMode = None (default since 1A-01), the textures of
`BattleAnimationManager` are not decoded at startup. If the player turns battle animations on in Options, they
load on demand through the lazy-loading API from 1A-04. The same applies to capture-animation images.

## Facts
- `BattleAnimationManager` ctor (`resource_management/battleanimationmanager.cpp:3-11`) registers
  `battleanimations/res.xml` (66 folders). `workerObject.cpp:174-175` runs its `loadAll()` (JS scripts).
- Settings gate only playback: `game/gameanimation/gameanimationfactory.cpp:588-612`.
- Settings: `coreengine/settings.cpp:488-496` (capture), `1771-1779` (battle mode).
- Which classes in `docs/tasks/data/resource-inventory.csv` are `battle_anim`/`capture_anim` tells you the files and the MB at stake.

## Design
- Keep the JS `loadAll()` (scripts are small and other code may query them). Make the **textures** lazy:
  call the 1A-04 API so ids are registered but not decoded.
- Make sure nothing at startup or during a match calls `getResAnim` on battle-animation ids while the mode is
  None. If something does (for example the wiki), it now triggers a lazy load, which is acceptable.
- Capture animation: find its textures through the inventory (`capture_anim`) and treat them the same way.

## Read list
- `resource_management/battleanimationmanager.cpp/.h`
- `resource_management/ressourcemanagement.h:120-260`
- The lazy-loading API comment in `3rd_party/oxygine-framework/oxygine/res/Resources.h` (from 1A-04)
- `game/gameanimation/gameanimationfactory.cpp:240-270`, `580-620`
- `docs/tasks/data/resource-inventory-summary.md`, and `grep battle_anim\|capture_anim docs/tasks/data/resource-inventory.csv | head -40`

## Files to modify
`resource_management/battleanimationmanager.cpp/.h`, the manager that owns capture-animation textures
(from the inventory), and minimal guarded hooks.

## Out of scope
Re-enabling animations (phase 2), CO/unit sprites.

## Acceptance criteria
1. Handheld build OK. The RAM run reaches the game.
2. `peak_rss_mb` drops versus 1A-05 by at least 60% of the `battle_anim` + `capture_anim` MB listed in the inventory summary. Write the expected number in the Result.
3. A second run with battle animations turned on shows no crash. Add `settings.setBattleAnimationMode(GameEnums.BattleAnimationMode_All)` in a copy of `tools/handheld/ramtest/init.js` (for example `tools/handheld/ramtest/init-anims-on.js`) and pass it with `measure-ram.sh -j`.
4. Desktop build still compiles: `.handheld/receipts/1A-07-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-07-build
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-07-build/build.log
tools/handheld/measure-ram.sh -l 1A-07-ram
tools/handheld/measure-ram.sh -l 1A-07-anims-on -j tools/handheld/ramtest/init-anims-on.js
tools/handheld/build-desktop-check.sh 1A-07-desktop
tools/jev-review.sh 1A-07
```

## Result

## Handoff notes
