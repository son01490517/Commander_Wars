# 1B-04 — First run on device and on-device RAM/FPS measurement

- **Status:** Skeleton (Opus details this card after 1A-90)
- **Difficulty:** medium
- **Depends on:** 1B-03

## Goal
Launch on the RG35XX Pro, fix startup issues (Panfrost/wayland), and port measure-ram.sh logic to the device (read /proc/<pid>/status, log FPS).

## Acceptance criteria (draft)
1. Game reaches a 2-player match on the device.
2. On-device peak RSS and FPS recorded as receipts; compare with 1A-90.

## Notes
Skeleton only: read list, exact files and verification commands are added when the device is available.
Do not start this card while its Status is `Skeleton`.
