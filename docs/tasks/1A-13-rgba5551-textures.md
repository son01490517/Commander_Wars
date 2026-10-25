# 1A-13 — (Conditional) RGBA5551 textures

- **Status:** Todo. **Only do this card if 1A-12's `peak_rss_mb` > 700.** Otherwise set Status to `Skipped`.
- **Difficulty:** hard
- **Depends on:** 1A-12
- **Context budget:** ~60k tokens

## Goal
In handheld builds, upload sprite textures as `GL_RGBA` + `GL_UNSIGNED_SHORT_5_5_5_1` (2 bytes per pixel)
instead of RGBA8888 when the image has no semi-transparent pixels. This halves texture memory for those images.

## Facts
- Upload site: `Texture::init` (`3rd_party/oxygine-framework/oxygine/core/opengl/texture.cpp:92-103`) uses
  `GL_RGBA, GL_UNSIGNED_BYTE`.
- An analysis of `resources/images` showed that 26% of the PNGs (35% of the pixels) are exactly representable in
  RGBA5551 (lossless). Most others have only small color shifts. Only about 1% of the PNGs have semi-transparent
  pixels; keep those in RGBA8888.
- GLES 3.1 on Panfrost and llvmpipe support `GL_UNSIGNED_SHORT_5_5_5_1`.

## Design
- Convert at upload time: check the alpha channel (only 0 or 255 → 5551 eligible). Pack the pixels into a
  temporary `quint16` buffer and upload it. Do not convert color-table textures (`resources/images/colortables`)
  or any texture used as shader lookup data. Check how `frac_table_shader.glsl` samples them.
- Shaders sample normalized values, so no shader change is needed for 5551.

## Read list
- `3rd_party/oxygine-framework/oxygine/core/opengl/texture.cpp/.h`
- `system/frac_table_shader.glsl`, `system/frac_matrix_shader.glsl`
- Where color tables are created: `game/player.cpp:195-206`, `game/co.h:836-837`

## Files to modify
`texture.cpp/.h` (guarded), plus a flag to opt out for lookup textures.

## Out of scope
Indexed palette textures (phase 2, card 2-04).

## Acceptance criteria
1. Handheld build OK. The RAM run reaches the game with `max_day_reached` ≥ 3.
2. `peak_rss_mb` drops versus 1A-12.
3. `.handheld/receipts/1A-13-ram/observation.txt` (written by you after comparing `shot.png` with the previous
   RAM receipt's `shot.png`) states whether unit and army colors look identical.
4. Desktop build still compiles: `.handheld/receipts/1A-13-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
tools/handheld/build-linux.sh > /dev/null
tools/handheld/measure-ram.sh -l 1A-13-ram
tools/handheld/build-desktop-check.sh 1A-13-desktop
tools/jev-review.sh 1A-13
```

## Result

## Handoff notes
