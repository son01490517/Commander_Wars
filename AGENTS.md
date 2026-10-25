# Agent instructions (handheld port)

This branch (`handheld`) ports Commander Wars to the Anbernic RG35XX Pro. Work is split into task cards.

## When the user's message is a card ID

If the user writes a card ID such as `1A-03` or `1B-07`, optionally with words like "làm", "do", "tiếp tục",
"continue", do this without asking for more context:

1. Read `docs/tasks/README.md` and follow its rules exactly.
2. Open the card: `docs/tasks/<ID>-*.md` (exactly one file matches), and its `docs/tasks/<ID>-*.criteria.json` if present.
3. Check *Status*:
   - `Todo`: check that every card in *Depends on* is `Done` (or `Skipped`) in the README table. If not, stop and say which one is missing.
   - `Blocked – Opus`: you are resuming. Read the card's *Handoff notes* and apply `docs/tasks/<ID>.wip.patch` if it exists (`git apply`), then continue.
   - `Done`, `Skipped` or `Skeleton`: stop and tell the user. Skeleton cards are detailed by Opus first.
4. Read only the card's *Read list* plus the files you modify. Do not explore the whole repo.
5. Do the work, run every command in *Verification*, then `tools/jev-review.sh <ID>` (at most 3 fix rounds).
6. Finish exactly as the README says: one commit `[<ID>] <title>` on success, or `[<ID>] blocked` with handoff notes and a patch.
7. Reply to the user in Vietnamese with a short summary: status, key numbers from `summary.json`, and the commit hash.

## Other requests

If the user does not give a card ID, behave normally. Still respect: all handheld behavior behind `HANDHELD_BUILD`
(see `docs/handheld-port-plan.md`), and never commit secrets, `*.ini` user settings or `.handheld/` receipts.

## Environment facts

- Docker image `cw-linux-arm64` and volumes `cw-build`, `cw-build-desktop` are used by `tools/handheld/*.sh`.
  The first run of `tools/handheld/build-linux.sh` builds the image automatically.
- Jev runs through `jev-decide` (on PATH) with `OPENROUTER_API_KEY` from the environment. Never print the key.
  No approval is needed per Jev call; the owner set a spending cap on OpenRouter.
