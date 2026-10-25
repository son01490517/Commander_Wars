# 1B-01 — Qt 6.10.3 + game cross-build image for ROCKNIX aarch64

- **Status:** Skeleton (Opus details this card after 1A-90)
- **Difficulty:** hard
- **Depends on:** 1A-90

## Goal
Docker image (arm64, native on M1) that builds a minimal Qt 6.10.3 (qtbase with EGL/GLES2+ and wayland, qtdeclarative, qtwayland, qttools for lrelease; no WebEngine/Multimedia) against a glibc not newer than ROCKNIX's, then builds the game with -DHANDHELD_BUILD=ON. Output: a relocatable install tree.

## Acceptance criteria (draft)
1. Binary and Qt libs run on the ROCKNIX glibc (check `objdump -T | grep GLIBC_` max version against ROCKNIX's).
2. Image build is reproducible from a Dockerfile in tools/handheld/docker/.

## Notes
Skeleton only: read list, exact files and verification commands are added when the device is available.
Do not start this card while its Status is `Skeleton`.
