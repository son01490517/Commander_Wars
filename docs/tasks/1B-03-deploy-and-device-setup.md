# 1B-03 — Deploy script (rsync/SSH) and device setup guide

- **Status:** Skeleton (Opus details this card after 1A-90)
- **Difficulty:** easy
- **Depends on:** 1B-02

## Goal
tools/handheld/deploy.sh <ip> (rsync to /storage/roms/ports/, restart over SSH) and docs/handheld-device-setup.md in Vietnamese: flashing ROCKNIX H700 image to a separate SD card, copying sun50i-h700-anbernic-rg35xx-pro.dtb, enabling WiFi + SSH, enabling zram, keeping the muOS card intact.

## Acceptance criteria (draft)
1. Guide covers every step from blank SD card to launching the port.
2. deploy.sh is idempotent and never deletes the user's savegames/maps.

## Notes
Skeleton only: read list, exact files and verification commands are added when the device is available.
Do not start this card while its Status is `Skeleton`.
