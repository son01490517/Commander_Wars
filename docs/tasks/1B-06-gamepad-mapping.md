# 1B-06 — Gamepad button mapping for RG35XX Pro

- **Status:** Skeleton (Opus details this card after 1A-90)
- **Difficulty:** medium
- **Depends on:** 1B-05

## Goal
Use the Linux joystick backend (coreengine/linux/Gamepad.cpp, coreengine/GamepadShared.cpp:23-30), GamepadEnabled default true on handheld. Mapping: A confirm, B cancel, X quick action, Y attack fields, L1 next unit, R1 compact info panel (1B-09), Select full FieldInfo, Start in-game menu (Escape), d-pad map cursor, left stick scroll/zoom, right stick + L2/R2 virtual mouse, Select+Start quit.

## Acceptance criteria (draft)
1. Every listed action works on the device.
2. Button indices verified on the device and documented.

## Notes
Skeleton only: read list, exact files and verification commands are added when the device is available.
Do not start this card while its Status is `Skeleton`.
