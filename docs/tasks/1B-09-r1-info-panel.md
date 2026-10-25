# 1B-09 — R1 compact unit/terrain info panel

- **Status:** Skeleton (Opus details this card after 1A-90)
- **Difficulty:** medium
- **Depends on:** 1B-07

## Goal
Non-modal compact panel toggled by R1 for the unit/terrain under the cursor (name, HP, fuel, ammo, terrain defense stars). Reuse the detailed box from game/ui/ingameinfobar.cpp:60-74 if practical.

## Acceptance criteria (draft)
1. R1 toggles the panel; it updates when the cursor moves.
2. Select still opens the full FieldInfo.

## Notes
Skeleton only: read list, exact files and verification commands are added when the device is available.
Do not start this card while its Status is `Skeleton`.
