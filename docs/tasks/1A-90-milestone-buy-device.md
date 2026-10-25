# 1A-90 — Milestone: confirm ≤700 MB, then buy the device

- **Status:** Todo
- **Difficulty:** easy
- **Depends on:** 1A-12 (and 1A-13 if it was not skipped)
- **Context budget:** ~20k tokens

## Goal
Confirm with fresh receipts on the current `handheld` head that the phase-1A target is met, then tell the
project owner to buy the RG35XX Pro.

## Steps
1. `git status` must be clean. Rebuild with `tools/handheld/build-linux.sh`.
2. Run `tools/handheld/measure-ram.sh -l 1A-90-ram` on `maps/2_player/Agitated.map` (24x22), and once more on a
   second 2-player map (`-m maps/2_player/<other>.map`, label `1A-90-ram2`). Check `map_size_and_players` in its
   `summary.json`; if the map is larger than 30x30, pick another map and rerun.
3. Copy the latest `1A-12-soak` numbers into the Result.
4. Run `tools/jev-review.sh 1A-90`.
5. In the Result, write a short Vietnamese summary for the owner: baseline versus now, per-card savings
   (from `.handheld/receipts/*/summary.json`), and the decision (mua máy / chưa đạt).

## Acceptance criteria
1. Both RAM runs: `reached_game=true` and `peak_rss_mb` ≤ 700.
2. Soak: `rss_growth_mb_per_hour` ≤ 50.
3. `estimated_device_turn_max_s` is reported. If > 30, list it as a 1B risk; it does not block buying the device.

## Verification
```bash
tools/handheld/build-linux.sh > /dev/null
tools/handheld/measure-ram.sh -l 1A-90-ram
tools/handheld/measure-ram.sh -l 1A-90-ram2 -m maps/2_player/<other>.map
tools/jev-review.sh 1A-90
```

## Result

## Handoff notes
