#!/bin/bash
# Self-review of a task card with Jev (via OpenRouter).
#
# Usage: tools/jev-review.sh <CARD_ID> [--commit <rev>] [--dry-run]
#   Without --commit the uncommitted working-tree diff (staged + unstaged + new files) is reviewed.
#   With --commit <rev> the diff of that single commit is reviewed.
#
# Evidence sent to Jev:
#   docs/tasks/<CARD_ID>-*.md              card text (goal, scope, acceptance criteria)
#   docs/tasks/<CARD_ID>-*.criteria.json   card-specific questions and threshold checks (optional)
#   tools/handheld/jev/common-questions.json questions asked for every card
#   .handheld/receipts/<CARD_ID>*/          command receipts (summary.json, *.log, *.txt)
#   the diff (secrets-looking files are excluded)
#
# Output: .handheld/jev/<CARD_ID>-<time>.{request,result}.json and a short summary.
# Exit code: 0 = all checks pass, 2 = needs fixing or human review, 1 = error.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
CARD="${1:-}"
[ -z "$CARD" ] && { echo "usage: $0 <CARD_ID> [--commit <rev>] [--dry-run]"; exit 1; }
shift
COMMIT=""; DRY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --commit) COMMIT="$2"; shift 2 ;;
        --dry-run) DRY="--dry-run"; shift ;;
        *) echo "unknown argument $1"; exit 1 ;;
    esac
done
CARD_FILES=("$REPO"/docs/tasks/"$CARD"-*.md)
[ ${#CARD_FILES[@]} -eq 1 ] && [ -f "${CARD_FILES[0]}" ] || { echo "need exactly one docs/tasks/$CARD-*.md"; exit 1; }
CARD_STEM="docs/tasks/$(basename "${CARD_FILES[0]}" .md)"
command -v jev-decide >/dev/null || { echo "jev-decide CLI not found (see jev-setup skill)"; exit 1; }

OUTDIR="$REPO/.handheld/jev"; mkdir -p "$OUTDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
REQ="$OUTDIR/$CARD-$STAMP.request.json"
RES="$OUTDIR/$CARD-$STAMP.result.json"
# Other cards' files are noise for this review: only this card's own files and the README are included.
EXCLUDE=(':(exclude)*.ini' ':(exclude)*.env' ':(exclude)*secret*' ':(exclude)*.key' ':(exclude).handheld'
         ':(exclude)docs/tasks')
OWN=("docs/tasks/README.md" "$CARD_STEM.md" "$CARD_STEM.criteria.json" "docs/tasks/$CARD.wip.patch")

cd "$REPO"
if [ -n "$COMMIT" ]; then
    DIFF="$(git show --stat --patch "$COMMIT" -- . "${EXCLUDE[@]}"; git show --format= --patch "$COMMIT" -- "${OWN[@]}")"
    REV="$(git rev-parse --short "$COMMIT")"
else
    git add -N . 2>/dev/null || true   # make new files visible to git diff (intent-to-add only)
    DIFF="$(git diff HEAD --stat --patch -- . "${EXCLUDE[@]}"; git diff HEAD --patch -- "${OWN[@]}")"
    REV="$(git rev-parse --short HEAD)-dirty"
fi

DIFF="$DIFF" REV="$REV" CARD="$CARD" CARD_STEM="$CARD_STEM" REQ="$REQ" python3 -I - <<'PY'
import json, os, re, glob
repo = os.getcwd(); card = os.environ["CARD"]
LIMIT_DIFF, LIMIT_CARD, LIMIT_RECEIPT = 120_000, 25_000, 12_000

def scrub(text):
    text = re.sub(r"sk-[A-Za-z0-9_\-]{16,}", "<redacted-key>", text)
    text = re.sub(r"/Users/[^/\s]+/", "/Users/<user>/", text)
    return text

def clip(text, limit, what):
    if len(text) <= limit:
        return text
    return text[:limit] + f"\n[... {what} truncated: {len(text) - limit} more characters not shown ...]"

stem = os.environ["CARD_STEM"]
card_text = open(f"{stem}.md", encoding="utf-8").read()
questions = json.load(open("tools/handheld/jev/common-questions.json", encoding="utf-8"))
crit_path = f"{stem}.criteria.json"
card_checks = {}
if os.path.exists(crit_path):
    crit = json.load(open(crit_path, encoding="utf-8"))
    for key, q in crit.get("questions", {}).items():
        questions[f"card_{key}"] = q
    card_checks = crit.get("threshold_checks", {})

receipts, threshold_checks = {}, {}
for d in sorted(glob.glob(f".handheld/receipts/{card}*")):
    for f in sorted(glob.glob(os.path.join(d, "*"))):
        if not f.endswith((".json", ".log", ".txt", ".csv")):
            continue
        body = open(f, encoding="utf-8", errors="replace").read()
        keep_tail = f.endswith(".log")
        if len(body) > LIMIT_RECEIPT:
            body = ("[... head truncated ...]\n" + body[-LIMIT_RECEIPT:]) if keep_tail else clip(body, LIMIT_RECEIPT, "receipt")
        receipts[os.path.relpath(f, repo)] = scrub(body)
        if f.endswith("summary.json"):
            try:
                s = json.loads(open(f).read())
                for name, rule in card_checks.items():
                    field, op, value = rule["field"], rule["op"], rule["value"]
                    actual = s.get(field)
                    ok = None if actual is None else {"<=": actual <= value, ">=": actual >= value, "==": actual == value}[op]
                    threshold_checks[f"{os.path.relpath(f, repo)}:{name}"] = {
                        "field": field, "actual": actual, "rule": f"{op} {value}", "passes": ok}
            except Exception as e:
                threshold_checks[os.path.relpath(f, repo)] = {"error": str(e)}

# One question per acceptance criterion, so a failing criterion is identified precisely.
m = re.search(r"^## Acceptance criteria[^\n]*\n(.*?)(?=^## |\Z)", card_text, re.S | re.M)
criteria_items = re.findall(r"^\d+\.\s+(.*?)(?=^\d+\.\s|\Z)", m.group(1), re.S | re.M) if m else []
for i, text in enumerate(criteria_items, 1):
    questions[f"criterion_{i}"] = {
        "type": "choice",
        "instructions": "Acceptance criterion " + str(i) + " of the card: \"" + " ".join(text.split()) + "\" "
                        "Is it met according to the diff, state.receipts, state.threshold_checks and "
                        "state.ram_history_all_cards? Numeric threshold_checks are computed by script; trust them.",
        "criteria": {
            "met": "The evidence shows this criterion is satisfied.",
            "not_met": "The evidence contradicts this criterion.",
            "unknown": "The evidence needed for this criterion is missing or truncated.",
        },
    }
if not criteria_items:
    questions["criteria_section_present"] = {"type": "noul",
        "instructions": "Does the card contain a numbered 'Acceptance criteria' section?",
        "criteria": {"true": "Yes.", "false": "No."}}

added = "\n".join(l for l in os.environ["DIFF"].splitlines() if l.startswith("+"))
secret_hits = re.findall(r"(sk-[A-Za-z0-9_\-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(?i:password|api[_-]?key|token)\s*[=:]\s*['\"][^'\"\s]{8,})", added)
secret_scan = f"{len(secret_hits)} match(es) for key/token/password patterns in added lines" + (
    ": " + ", ".join(h[:12] + "..." for h in secret_hits[:5]) if secret_hits else "")

ram_history = {}
for f in sorted(glob.glob(".handheld/receipts/*/summary.json")):
    try:
        s = json.loads(open(f).read())
        ram_history[os.path.basename(os.path.dirname(f))] = {k: s.get(k) for k in (
            "git_rev", "menu_only", "reached_game", "menu_rss_mb", "peak_rss_mb", "max_day_reached")}
    except Exception:
        pass

request = {
    "model": "typesafe/jev-1.13",
    "state": {
        "project": "Port of the Commander Wars game (Qt6 + oxygine + QJSEngine, C++20) to the "
                   "Anbernic RG35XX Pro handheld (1 GB RAM, 640x480) running ROCKNIX. All handheld "
                   "changes must stay behind the CMake option HANDHELD_BUILD so desktop builds are unchanged.",
        "card_id": card,
        "card": scrub(clip(card_text, LIMIT_CARD, "card")),
        "reviewed_revision": os.environ["REV"],
        "diff": scrub(clip(os.environ["DIFF"], LIMIT_DIFF, "diff")) or "(empty diff)",
        "receipts": receipts or "(no receipts found under .handheld/receipts/" + card + "*)",
        "threshold_checks": threshold_checks or "(none)",
        "ram_history_all_cards": ram_history or "(none)",
        "secret_scan": secret_scan,
    },
    "questions": questions,
}
json.dump(request, open(os.environ["REQ"], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY

set +e
jev-decide decide "$REQ" --provider openrouter $DRY > "$RES"
CODE=$?
set -e
[ -n "$DRY" ] && { echo "dry run OK, request: $REQ"; exit $CODE; }

RES="$RES" REQ="$REQ" python3 -I - <<'PY'
import json, os, sys
try:
    r = json.load(open(os.environ["RES"]))
    decisions = r["decisions"]
    asked = json.load(open(os.environ["REQ"]))["questions"]
    assert isinstance(decisions, dict) and set(asked) <= set(decisions)
except Exception as e:
    print(f"RESULT: ERROR (unreadable or incomplete Jev result: {e}) | {os.environ['RES']}")
    sys.exit(1)

# Values that mean "this card is not done yet" for the common questions.
fail_if = {
    "guarded_by_handheld": {"unguarded", "unknown"},
    "out_of_scope_edits": {True},
    "weakens_checks": {True},
    "receipts_valid": {"invalid", "missing"},
    "leaks_secrets": {True},
}
bad = 0
print(f"   {'question':32} {'status':13} {'value':16} prob")
for key in asked:
    d = decisions[key]
    status, value, prob = d.get("status"), d.get("value"), d.get("probability")
    if d.get("status") == "scored":          # score questions: value is an expected level (0..n-1)
        failing = value is None or value >= 1.5
        note = "  <- check manually" if value is not None and 0.75 <= value < 1.5 else ""
    else:
        failing = status != "selected" or value in fail_if.get(key, set())
        if key.startswith("criterion_") and value != "met":
            failing = True
        if key.startswith("card_") and value in (False, "no", "unknown", "not_met", "fail"):
            failing = True               # card questions are phrased so that true / "yes" means OK
        note = ""
    bad += failing
    shown = f"{value:.2f}" if isinstance(value, float) else str(value)
    print(f"{'!! ' if failing else '   '}{key:32} {str(status):13} {shown:16} {'' if prob is None else prob}{note}")
cost = (r.get("response") or {}).get("usage", {}).get("cost")
print("RESULT:", "PASS" if bad == 0 else f"FIX NEEDED ({bad} item(s))",
      f"| cost ${cost:.4f}" if isinstance(cost, (int, float)) else "", "| full result:", os.environ["RES"])
sys.exit(0 if bad == 0 else 2)
PY
