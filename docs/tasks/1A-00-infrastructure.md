# 1A-00 — Measurement and review infrastructure

- **Status:** Done (Opus)
- **Difficulty:** easy
- **Depends on:** —
- **Context budget:** ~40k tokens

## Goal
Provide the shared tooling every later card uses: a Linux arm64 Docker build, an automated
RAM measurement of a 2-player AI-vs-AI match at 640x480, and a Jev self-review script.

## Why
The RG35XX Pro has 1 GB RAM shared between CPU and GPU. Every optimization card must prove
its effect with the same reproducible measurement, and every card must pass the same review gate.

## Files to modify
- `tools/handheld/docker/Dockerfile.measure` (new)
- `tools/handheld/build-linux.sh` (new)
- `tools/handheld/measure-ram.sh` (new)
- `tools/handheld/ramtest/init.js` (new)
- `tools/handheld/jev/common-questions.json` (new)
- `tools/jev-review.sh` (new)
- `.gitignore` (add `.handheld/`)
- `docs/handheld-port-plan.md`, `docs/handheld-map-making.md`, `docs/tasks/*` (new)

## Out of scope
- Any change to game C++/JS/CMake sources.

## Acceptance criteria
1. `tools/handheld/build-linux.sh` prints `BUILD_OK`.
2. `tools/handheld/measure-ram.sh -l 1A-00-baseline` produces `summary.json` with
   `reached_game=true`, a 2-player map no larger than 30x30 and `seconds_run == seconds_requested`.
3. `tools/jev-review.sh 1A-00` completes a real OpenRouter call and prints a table of decisions followed by a
   `RESULT:` line (either PASS or FIX NEEDED proves the pipeline works). Receipts: `.handheld/receipts/1A-00-jev/*.txt`.
4. No game source file is modified.

## Verification
```bash
tools/handheld/build-linux.sh | tee .handheld/receipts/1A-00-build/build.log   # mkdir first
tools/handheld/measure-ram.sh -l 1A-00-baseline
tools/jev-review.sh 1A-00
```

## Result
Baseline (git b80b83a69, Ubuntu 25.10 arm64, Qt 6.9.2, llvmpipe, 640x480, map Agitated 24x22, 2 Normal AIs, 360 s):
`menu_rss_mb` = **1431**, `peak_rss_mb` = **1562**, end 1459, `max_day_reached` = 13. Target: ≤ 700.

Jev review: `RESULT: PASS` (`.handheld/receipts/1A-00-jev/review-final.txt`), about $0.0013 per review call.
Lesson: write each acceptance criterion so that a single receipt proves it; `jev-review.sh` asks one question
per criterion (`criterion_N`).
