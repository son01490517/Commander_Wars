# 1B-05 — Keyboard/gamepad map cursor without OS pointer

- **Status:** Skeleton (Opus details this card after 1A-90)
- **Difficulty:** medium
- **Depends on:** 1B-04

## Goal
Keyboard/gamepad cursor movement is ignored when the OS pointer is outside the window (`calcNewMousePosition` returns early unless `hasCursor()`, 3rd_party/oxygine-framework/oxygine/core/gamewindow.cpp:458; menue/basegamemenu.cpp:404). Make it work on the handheld.

## Acceptance criteria (draft)
1. D-pad/arrow keys move the map cursor with no mouse present.
2. Desktop behavior unchanged.

## Notes
Skeleton only: read list, exact files and verification commands are added when the device is available.
Do not start this card while its Status is `Skeleton`.
