# 1A-06 — Resource inventory and classification

- **Status:** Todo
- **Difficulty:** medium
- **Depends on:** 1A-03
- **Context budget:** ~60k tokens

## Goal
Produce a data table of **every image resource loaded at startup**, with its manager, id, file, size and decoded
bytes, plus a class for each row. Cards 1A-07 to 1A-09 use this table to decide what to load lazily.

Classes:
- `always`: UI, fonts, cursors, icons, terrain and buildings that any map may need
- `per_co`: CO portraits and faces of one CO
- `per_army`: army-specific unit or building sprites
- `battle_anim`: battle animation sprites
- `capture_anim`: capture animation sprites
- `unused_handheld`: not needed on the handheld (for example wiki-only or editor-only images)

## Steps
1. Add a handheld-only debug dump: when the environment variable `CW_RES_INVENTORY=<path>` is set, after
   startup loading finishes, write a CSV `manager,id,file,width,height,bytes` for every `ResAnim` of every
   `RessourceManagement` subclass and `BackgroundManager`. Hook point: the end of startup loading in
   `coreengine/workerObject.cpp:151-192`.
2. Add `tools/handheld/inventory/classify.py` (Python standard library only). It assigns classes by **path
   rules** (for example `images/co/<army>/` → `per_co`, `images/battleanimations/` → `battle_anim`) and writes
   the rows it cannot classify to `ambiguous.jsonl`.
3. Classify the ambiguous rows with **Jev triage** in batches of ≤ 40 rows per request:
   `jev-decide decide <request.json> --provider openrouter`. Use one `choice` question per row with the class
   labels above plus `unknown`. Give each row its manager, id, file path and size. Rows answered `unknown` or
   `needs_review` get the class `always` (the safe default).
4. Commit the final table to `docs/tasks/data/resource-inventory.csv` (columns plus `class`, `class_source`
   = `rule|jev|default`) and a summary `docs/tasks/data/resource-inventory-summary.md` with MB per class.

## Read list
- `resource_management/ressourcemanagement.h:120-260`
- `3rd_party/oxygine-framework/oxygine/res/Resources.h` (list/iterate API)
- `coreengine/workerObject.cpp:140-200`
- `3rd_party/oxygine-framework/oxygine/core/renderer.cpp:70-140` (manager creation order)
- `tools/handheld/measure-ram.sh` (pass the env var through `docker run -e` if you extend it)

## Files to modify
`coreengine/workerObject.cpp` (guarded dump call), a small helper in `resource_management/` if needed,
`tools/handheld/inventory/*` (new), `tools/handheld/measure-ram.sh` (optional `-e CW_RES_INVENTORY`),
`tools/handheld/inventory/jev-triage.sh` (new), `docs/tasks/data/*` (new).

## Out of scope
Changing what is loaded (later cards).

## Acceptance criteria
1. `.handheld/receipts/1A-06-inventory/inventory.csv` exists and covers all managers (`classify.txt` prints rows and MB per manager). The sum of `bytes` lies between 150 and 600 MB (sanity check against the ≈530 MB measured earlier; backgrounds may be missing if 1A-04 made them lazy).
2. Every row has a class. The `jev` and `default` sources are counted in the summary.
3. Jev request/result files for the triage are kept under `.handheld/receipts/1A-06-jev/`, and `triage.txt` shows how many rows got each class.
4. Desktop build still compiles: `.handheld/receipts/1A-06-desktop/build.log` ends with `DESKTOP_BUILD_OK`.

## Verification
```bash
mkdir -p .handheld/receipts/1A-06-build .handheld/receipts/1A-06-jev
tools/handheld/build-linux.sh 2>&1 | tee .handheld/receipts/1A-06-build/build.log
# menu-only run; the game writes the CSV to /out, which is the receipt folder
tools/handheld/measure-ram.sh -l 1A-06-inventory -s 90 -M -e CW_RES_INVENTORY=/out/inventory.csv
python3 -I tools/handheld/inventory/classify.py .handheld/receipts/1A-06-inventory/inventory.csv docs/tasks/data/ \
    | tee .handheld/receipts/1A-06-inventory/classify.txt
tools/handheld/inventory/jev-triage.sh docs/tasks/data/ambiguous.jsonl .handheld/receipts/1A-06-jev/ \
    | tee .handheld/receipts/1A-06-jev/triage.txt          # new script: batches of <=40 rows, writes classes back
python3 -I tools/handheld/inventory/classify.py --merge docs/tasks/data/ | tee .handheld/receipts/1A-06-inventory/merge.txt
tools/handheld/build-desktop-check.sh 1A-06-desktop
tools/jev-review.sh 1A-06
```

## Result

## Handoff notes
