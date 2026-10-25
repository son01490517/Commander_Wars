# 1A-05 — 640x480 background assets for the handheld package

- **Status:** Todo
- **Difficulty:** medium
- **Depends on:** 1A-04
- **Context budget:** ~35k tokens

## Goal
Create a reproducible asset step that turns every `resources/images/backgrounds/*.jpg` (1536x864, 16:9) into a
640x480 (4:3) version: center-crop to 1152x864, then resize to 640x480, JPEG quality 90. Write the output to an
**overlay folder** `.handheld/overlay/resources/images/backgrounds/`. Files in the user path override files
in the game folder (`coreengine/virtualpaths.cpp:26-58`, user path is searched first), so the overlay is used
by copying it into the user path. Originals in `resources/` stay untouched, so desktop is unchanged.

## Why
Each decoded original is 5.3 MB. The 640x480 version is 1.2 MB, and the screen is 640x480 anyway.

## Read list
- `coreengine/virtualpaths.cpp:20-70` (search order)
- `resources/images/backgrounds/res.xml` (check whether entries declare a size; if they do, the overlay must not break it)
- `ui_reader/createdgui.cpp:260-270` (background is scaled to the stage)
- `tools/handheld/measure-ram.sh`

## Files to modify
- `tools/handheld/assets/make-backgrounds.sh` (new; uses ImageMagick `convert`, already in the Docker image,
  and runs inside the `cw-linux-arm64` container so the result does not depend on the host)
- `tools/handheld/measure-ram.sh`: if `.handheld/overlay/` exists, copy it into the user path `$U` before starting the game
- `.gitignore` only if needed (the overlay lives under `.handheld/`, which is already ignored)

## Out of scope
Changing `res.xml`, changing PNG backgrounds, packaging for the device (1B-02 reuses the overlay).

## Acceptance criteria
1. `tools/handheld/assets/make-backgrounds.sh` creates 65 JPGs of exactly 640x480 (receipt: `identify` listing).
2. The RAM run with the overlay reaches the game. `menu_rss_mb` is not higher than 1A-04 (expected slightly lower).
3. `.handheld/receipts/1A-05-menu/observation.txt` (written by you after looking at `shot.png`) states that the
   background fills the screen without black bars or visible stretching.

## Verification
```bash
mkdir -p .handheld/receipts/1A-05-assets
tools/handheld/assets/make-backgrounds.sh 2>&1 | tee .handheld/receipts/1A-05-assets/make.log
docker run --rm -v "$PWD/.handheld/overlay":/o cw-linux-arm64 bash -c 'identify /o/resources/images/backgrounds/*.jpg' > .handheld/receipts/1A-05-assets/identify.txt
grep -c " 640x480 " .handheld/receipts/1A-05-assets/identify.txt | tee .handheld/receipts/1A-05-assets/count.txt
tools/handheld/measure-ram.sh -l 1A-05-ram
tools/handheld/measure-ram.sh -l 1A-05-menu -s 40 -M
# write .handheld/receipts/1A-05-menu/observation.txt
tools/jev-review.sh 1A-05
```

## Result

## Handoff notes
