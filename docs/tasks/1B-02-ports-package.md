# 1B-02 — ROCKNIX Ports package and launcher

- **Status:** Skeleton (Opus details this card after 1A-90)
- **Difficulty:** medium
- **Depends on:** 1B-01

## Goal
Assemble `CommanderWars/` (binary, bundled Qt libs + plugins incl. platforms/libqwayland*, resources/, maps/, the 640x480 background overlay from 1A-05) and `CommanderWars.sh` launcher for /storage/roms/ports/: sets LD_LIBRARY_PATH, QT_QPA_PLATFORM=wayland, QT_PLUGIN_PATH, runs with --userPath pointing at the game folder, logs to a file.

## Acceptance criteria (draft)
1. Package tree and launcher produced by a script in tools/handheld/.
2. Launcher works in Docker smoke test (QT_QPA_PLATFORM=offscreen) without missing-library errors.

## Notes
Skeleton only: read list, exact files and verification commands are added when the device is available.
Do not start this card while its Status is `Skeleton`.
