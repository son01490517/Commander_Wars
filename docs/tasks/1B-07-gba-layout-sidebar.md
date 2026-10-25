# 1B-07 — GBA layout: hide sidebar, full-width map

- **Status:** Skeleton (Opus details this card after 1A-90)
- **Difficulty:** hard
- **Depends on:** 1B-04

## Goal
Under a handheld setting, do not create IngameInfoBar/PlayerInfo sidebar (menue/gamemenue.cpp:1600-1625) and let the map use the full stage width (initSlidingActor, menue/basegamemenu.cpp:459-483). Null-guard minimap/cursor/player-info hooks (gamemenue.cpp:1643, 1669-1672, 1980-2007). Check replay (menue/replaymenu.cpp:213-319) and movement planner (movementplanner.cpp:30).

## Acceptance criteria (draft)
1. Map fills 640x480 in matches.
2. Replay and movement planner still open without crashes.

## Notes
Skeleton only: read list, exact files and verification commands are added when the device is available.
Do not start this card while its Status is `Skeleton`.
