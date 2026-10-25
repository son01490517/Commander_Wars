# 1A-12 — 60-minute soak test and AI turn timing

- **Status:** Todo
- **Difficulty:** medium
- **Depends on:** 1A-09 (run it again after any later RAM card)
- **Context budget:** ~40k tokens

## Goal
1. Show that RAM does not grow without bound during a long session: a 60-minute AI-vs-AI run on a 2-player
   map ≤ 30x30, with automatic restart of a new match after victory (the session goal is "≥ 60 min without
   being killed").
2. Measure the time of each AI turn in Docker on the M1, so the device time can be estimated. The H700 is about
   8–15x slower than one M1 core. The target on the device is ≤ 30 s per turn.

## Steps
- Extend `tools/handheld/measure-ram.sh` with an option `-r` (restart): the automation script starts a new
  match after `onVictory`. Keep the default behavior unchanged.
- Log per-turn timing. Prefer a JS-side marker in the automation script if a per-turn hook exists. Otherwise add
  a handheld-only debug log line at the start and end of each AI turn (search `ai/coreai.cpp` for the turn entry,
  e.g. `process()` / `finishTurn`). Parse it into `ai-turns.csv` (`day,player,seconds`).
- Report in `summary.json`: `rss_growth_mb_per_hour` (linear fit over the game phase), `ai_turn_p50_s`,
  `ai_turn_max_s`, `estimated_device_turn_max_s` (= max × 12).

## Read list
- `tools/handheld/measure-ram.sh`, `tools/handheld/ramtest/init.js`
- `ai/coreai.cpp`: only the turn entry/exit functions (find with `grep -n "void CoreAI::process\|finishTurn" ai/coreai.cpp`)
- `ai/normalai.cpp`: the `process()` function only

## Files to modify
`tools/handheld/measure-ram.sh`, `tools/handheld/ramtest/init.js`, and a guarded log line in `ai/coreai.cpp` if needed.

## Out of scope
Optimizing AI speed (if the estimate exceeds 30 s, Opus creates follow-up cards).

## Acceptance criteria
1. `seconds_run` = 3600, and the game stayed in matches for the whole run (restarts allowed).
2. `rss_growth_mb_per_hour` ≤ 50 and `peak_rss_mb` is reported.
3. `ai-turns.csv` has at least 30 turns, and the AI turn statistics are in `summary.json`.
4. Desktop build still compiles: `.handheld/receipts/1A-12-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
tools/handheld/build-linux.sh > /dev/null
tools/handheld/measure-ram.sh -l 1A-12-soak -s 3600 -r
tools/handheld/build-desktop-check.sh 1A-12-desktop
tools/jev-review.sh 1A-12
```

## Result

## Handoff notes
