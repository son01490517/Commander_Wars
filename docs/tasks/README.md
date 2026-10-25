# Task cards: Commander Wars handheld port

Kế hoạch tổng: `docs/handheld-port-plan.md`. Card viết bằng tiếng Anh để mọi AI (DeepSeek, Antigravity,
Claude…) đọc chính xác. Cột "Tóm tắt" ghi bằng tiếng Việt.

## How to work a card (rules for every AI)

1. Work cards **in order**, on branch `handheld`. Check that every card listed in *Depends on* is `Done`.
2. Read **only** what the card's *Read list* names, plus files you modify. Stay within ~100k tokens of
   context (hard limit 200k). If the card cannot fit, stop and mark it `Blocked – Opus` with that reason.
3. Make the change. Every behavior change must be compiled only under `HANDHELD_BUILD`
   (C++ `#ifdef HANDHELD_BUILD`, JS/XML `settings.getHandheldBuild()` once card 1A-01 is done), or be a
   setting whose default keeps desktop behavior.
4. Run every command in *Verification*, saving output under `.handheld/receipts/<CARD_ID>-*/`.
5. Run `tools/jev-review.sh <CARD_ID>` (example: `tools/jev-review.sh 1A-03`).
   `RESULT: PASS` means you are done. On `FIX NEEDED`, fix and rerun, **at most 3 rounds**.
6. **Success:** set the card's *Status* to `Done (<your AI name>)`, fill in *Result* (numbers from
   `summary.json`), update the table below, and make **one commit** titled `[<CARD_ID>] <title>`.
7. **Failure after 3 rounds:** do not commit broken code. Save the work with
   `git diff > docs/tasks/<CARD_ID>.wip.patch` and restore a clean tree (`git checkout -- . && git clean -fd`,
   keeping the patch file). Then set *Status* to `Blocked – Opus` and write *Handoff notes* (what you
   tried, the error with a short log excerpt, and where you suspect the cause). Update the table and commit
   only the card, the patch and this README, titled `[<CARD_ID>] blocked`.
8. Opus resumes a blocked card from its ID alone: card + *Handoff notes* + `.wip.patch`.

If a criterion keeps coming back `needs_review` only because its wording is ambiguous, you may clarify the wording
of that criterion, but never lower a number or remove a requirement (`weakens_checks` checks this).

Common tools: `tools/handheld/build-linux.sh` (Docker arm64 build, prints `BUILD_OK`),
`tools/handheld/build-desktop-check.sh <label>` (normal desktop build, prints `DESKTOP_BUILD_OK`),
`tools/handheld/measure-ram.sh -l <label> [-s sec] [-m map] [-M] [-j init.js] [-e KEY=VAL]` (default: 6-minute
2-player match at 640x480, writes `summary.json`, `ram.csv`, `game.log`, `markers.log`, `shot.png`),
`tools/jev-review.sh <CARD_ID>`.

RAM rule: when a card asks for a RAM receipt, run `measure-ram.sh -l <CARD_ID>-ram` and compare
`peak_rss_mb` with the previous card's *Result*.

## Phase 1A: optimize on Mac + Docker (before buying the device)

| ID | Title | Tóm tắt | Diff. | Depends | Status |
|---|---|---|---|---|---|
| 1A-00 | Measurement and review infrastructure | Công cụ build, đo RAM, Jev review | easy | — | Done (Opus) |
| 1A-01 | HANDHELD_BUILD option and handheld defaults | Cờ build và mặc định cho máy cầm tay (tắt animation, MSAA, zoom 1x) | medium | 1A-00 | Todo |
| 1A-02 | Hide Multiplayer button on handheld | Ẩn nút Multiplayer | easy | 1A-01 | Todo |
| 1A-03 | Release CPU image copies after GPU upload | Giải phóng bản ảnh trong RAM sau khi đẩy lên GPU | hard | 1A-01 | Todo |
| 1A-04 | Load menu backgrounds on demand | Ảnh nền: mỗi lần chỉ nạp 1 ảnh | hard | 1A-03 | Todo |
| 1A-05 | 640x480 background assets for the handheld package | Ảnh nền cắt 4:3, thu nhỏ còn 640x480 | medium | 1A-04 | Todo |
| 1A-06 | Resource inventory and classification | Thống kê sprite đang nạp, phân loại (script + Jev triage) | medium | 1A-03 | Todo |
| 1A-07 | Skip battle/capture animation resources when disabled | Không nạp battle/capture animation khi đã tắt | hard | 1A-06 | Todo |
| 1A-08 | Load CO sprites only for COs in the match | Chỉ nạp sprite CO có trong trận | hard | 1A-06 | Todo |
| 1A-09 | Load army-specific unit/building sprites only for armies in the match | Chỉ nạp sprite unit/công trình của các phe trong trận | hard | 1A-08 | Todo |
| 1A-10 | Stream music instead of decoding whole tracks | Phát nhạc dạng streaming | hard | 1A-01 | Todo |
| 1A-11 | 640x480 UI screenshot audit | Chụp mọi màn hình ở 640x480 để tìm chỗ tràn | medium | 1A-01 | Todo |
| 1A-12 | 60-minute soak test and AI turn timing | Chạy 60 phút, đo RAM tăng và thời gian lượt AI | medium | 1A-09 | Todo |
| 1A-13 | (Conditional) RGBA5551 textures | (Chỉ khi cần) Texture 16-bit | hard | 1A-12 | Todo |
| 1A-90 | Milestone: confirm ≤700 MB, then buy the device | Xác nhận đạt mốc rồi mua máy | easy | 1A-12 (and 1A-13 if run) | Todo |

UI fixes found by 1A-11 are added by Opus as cards `1A-2x`.

## Phase 1B: on the device (skeleton cards, detailed after 1A-90)

| ID | Title | Tóm tắt | Diff. | Depends | Status |
|---|---|---|---|---|---|
| 1B-01 | Qt 6.10.3 + game cross-build image for ROCKNIX aarch64 | Build Qt 6.10.3 cho ROCKNIX | hard | 1A-90 | Skeleton |
| 1B-02 | ROCKNIX Ports package and launcher | Đóng gói thư mục Ports + script chạy | medium | 1B-01 | Skeleton |
| 1B-03 | Deploy script (rsync/SSH) and device setup guide (ROCKNIX, DTB, zram) | Script deploy + hướng dẫn cài ROCKNIX | easy | 1B-02 | Skeleton |
| 1B-04 | First run on device and on-device RAM/FPS measurement | Chạy lần đầu, đo RAM/FPS trên máy | medium | 1B-03 | Skeleton |
| 1B-05 | Keyboard/gamepad map cursor without OS pointer (hasCursor) | Con trỏ map chạy được khi không có chuột | medium | 1B-04 | Skeleton |
| 1B-06 | Gamepad button mapping for RG35XX Pro | Gán nút gamepad | medium | 1B-05 | Skeleton |
| 1B-07 | GBA layout: hide sidebar, full-width map | Bỏ thanh bên phải, map toàn màn hình | hard | 1B-04 | Skeleton |
| 1B-08 | GBA layout: corner CO/funds/power box that dodges the cursor | Ô CO/tiền/power ở góc tự né con trỏ | medium | 1B-07 | Skeleton |
| 1B-09 | R1 compact unit/terrain info panel | Panel thông tin nhỏ khi bấm R1 | medium | 1B-07 | Skeleton |
| 1B-10 | Minimap in the Start menu; optional corner terrain box | Minimap trong menu Start; ô địa hình tùy chọn | medium | 1B-07 | Skeleton |
| 1B-11 | Package size: lossless PNG and re-encoded OGG for the handheld package | Giảm dung lượng gói | easy | 1B-02 | Skeleton |
| 1B-12 | 60-minute on-device soak, AI turn ≤30 s, ≥30 FPS sign-off | Nghiệm thu trên máy | medium | 1B-06…1B-10 | Skeleton |

## Phase 2: later (titles only)

- 2-01 Map editor usable with sticks and buttons on the device
- 2-02 Online AI: Mac/server hosts a multiplayer match with AI slots, handheld joins as client
- 2-03 Re-enable battle animations with on-demand loading if RAM allows
- 2-04 Indexed 8-bit palette textures (only if more RAM headroom is needed)
