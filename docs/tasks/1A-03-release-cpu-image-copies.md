# 1A-03 — Release CPU image copies after GPU upload

- **Status:** Todo
- **Difficulty:** hard
- **Depends on:** 1A-01
- **Context budget:** ~70k tokens

## Goal
After a texture's pixels are uploaded to the GPU and its hit-test masks are built, drop the CPU-side
`QImage` held by `oxygine::Texture` in handheld builds. On the RG35XX, CPU and GPU share the same 1 GB, so
today every image costs RAM twice.

## Why (measured)
- All game images decode to about 530 MB of RGBA (4,763 PNG ≈ 185 MB, 65 background JPG ≈ 345 MB).
- Baseline RSS is 1.43 GB in the main menu (`.handheld/receipts/1A-00-baseline/summary.json`).
- `Texture::m_image` (`3rd_party/oxygine-framework/oxygine/core/opengl/texture.h:60`) keeps the decoded
  image alive for the whole run (`texture.cpp:99` assigns it; nothing ever clears it).
- The only reader of `Texture::getImage()` is `AnimationFrame::updateHittestdata`
  (`3rd_party/oxygine-framework/oxygine/AnimationFrame.cpp:21-45`), which builds a 1-bit hit mask.
- `Texture::getWidth()`/`getHeight()` (`texture.h:22-29`) read `m_image`, so cache width/height first.

## Design constraints
- Release the image only **after all AnimationFrames of that texture have been created** (frames are
  created in `ResAnim::init`, `3rd_party/oxygine-framework/oxygine/res/ResAnim.cpp:30-100`). Do not release
  inside `Texture::init`.
- If `updateHittestdata` is ever called on a texture whose image was released, it must not crash: fall back
  to "whole rect is hittable" and log once at debug level.
- Textures created at runtime from generated images (CO recolors, color tables, map previews) can be
  released the same way only if they go through the same `ResAnim::init` path. Do not change other classes.
- Context-loss restore: confirm nothing re-uploads from `m_image` after `Texture::release()`
  (search `->init(` on textures). If something does, keep the image for that texture.
- Under `#ifndef HANDHELD_BUILD` the behavior must be byte-for-byte unchanged.

## Read list
- `3rd_party/oxygine-framework/oxygine/core/opengl/texture.h` (whole, ~70 lines)
- `3rd_party/oxygine-framework/oxygine/core/opengl/texture.cpp` (whole, ~110 lines)
- `3rd_party/oxygine-framework/oxygine/AnimationFrame.cpp:1-60` and its header
- `3rd_party/oxygine-framework/oxygine/res/ResAnim.cpp:20-110` and `ResAnim.h`
- `3rd_party/oxygine-framework/oxygine/res/ResAtlasGeneric.cpp:60-240` (decode + `loadAtlas`)
- `3rd_party/oxygine-framework/oxygine/core/none/texture.cpp` (non-graphics backend, keep compiling)
- `grep -rn "getImage()\|Texture::init\|->init(" 3rd_party/oxygine-framework` output

## Files to modify
`texture.h`, `texture.cpp`, `AnimationFrame.cpp` (+ header if needed), `ResAnim.cpp` (+ header if needed).

## Out of scope
Background lazy loading (1A-04), per-match loading (1A-08/09), texture formats (1A-13).

## Acceptance criteria
1. Handheld build OK. The RAM run reaches the game with no new `Critical`/`Fatal` lines in `markers.log`.
2. `menu_rss_mb` and `peak_rss_mb` drop by at least 300 MB compared with the 1A-01 result.
3. Clicking still works: the RAM run's `game.log` shows the match progressing (`max_day_reached` ≥ 3).
4. Desktop code path unchanged (`#ifdef HANDHELD_BUILD` around every behavior change).
5. Desktop build still compiles: `.handheld/receipts/1A-03-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-03-build
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-03-build/build.log
tools/handheld/measure-ram.sh -l 1A-03-ram
tools/handheld/build-desktop-check.sh 1A-03-desktop
tools/jev-review.sh 1A-03
```

## Result

## Handoff notes
