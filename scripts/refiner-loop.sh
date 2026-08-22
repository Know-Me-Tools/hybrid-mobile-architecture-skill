#!/usr/bin/env bash
# scripts/refiner-loop.sh
# Drive the 5-stage reactive skill-refinement loop:
#
#   Detect -> Triage -> [HALT] -> Refine -> Verify -> Ship
#
# The loop HALTS after Triage and will not continue without an explicit human
# decision. A producer does not grade its own work: whoever writes the fix must
# not also be the one who rules the diagnosis correct.
#
# Usage:
#   refiner-loop.sh --skill NAME --evidence TEXT [--source log|sycophancy|user]
#                                  [--replay 'COMMAND']
#
#   --replay records a command that REPRODUCED the failure. `--verify` executes
#   it with `eval` in the repo root and expects exit 0 once the fix lands.
#   Ticket files are therefore TRUSTED INPUT: verifying a ticket runs its
#   replay string as shell.
#                                       open a ticket and run Detect + Triage
#   refiner-loop.sh --list              list open tickets
#   refiner-loop.sh --show TICKET       print one ticket
#   refiner-loop.sh --approve TICKET    record approval; unblocks Refine
#   refiner-loop.sh --reject TICKET --reason TEXT   close without a change
#   refiner-loop.sh --verify TICKET     run the verification gate
#   refiner-loop.sh --ship TICKET       mark shipped (requires a passed verify)
#
# Tickets live under .prometheus/refiner/ as JSON, one file per ticket, so the
# evidence that opened a ticket stays attached to it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TICKET_DIR="$REPO_ROOT/.prometheus/refiner"

SKILL=""
EVIDENCE=""
REPLAY=""
SOURCE="user"
REASON=""
ACTION=""
TICKET=""

usage() { sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --skill)    SKILL="${2:?--skill needs a value}"; shift 2 ;;
    --evidence) EVIDENCE="${2:?--evidence needs a value}"; shift 2 ;;
    --replay)   REPLAY="${2:?--replay needs a value}"; shift 2 ;;
    --source)   SOURCE="${2:?--source needs a value}"; shift 2 ;;
    --reason)   REASON="${2:?--reason needs a value}"; shift 2 ;;
    --list)     ACTION="list"; shift ;;
    --show)     ACTION="show";    TICKET="${2:?--show needs a ticket}"; shift 2 ;;
    --approve)  ACTION="approve"; TICKET="${2:?--approve needs a ticket}"; shift 2 ;;
    --reject)   ACTION="reject";  TICKET="${2:?--reject needs a ticket}"; shift 2 ;;
    --verify)   ACTION="verify";  TICKET="${2:?--verify needs a ticket}"; shift 2 ;;
    --ship)     ACTION="ship";    TICKET="${2:?--ship needs a ticket}"; shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "refiner-loop: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

mkdir -p "$TICKET_DIR"

ticket_path() { printf '%s/%s.json' "$TICKET_DIR" "$1"; }

require_ticket() {
  local path
  path="$(ticket_path "$1")"
  [ -f "$path" ] || { echo "refiner-loop: no such ticket: $1" >&2; exit 1; }
  printf '%s' "$path"
}

ticket_field() {
  python3 -c '
import json, sys
print(json.load(open(sys.argv[1])).get(sys.argv[2], ""))
' "$1" "$2"
}

set_fields() {
  # set_fields <path> <key=value>...
  local path="$1"; shift
  python3 -c '
import json, os, sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    ticket = json.load(handle)
# Boolean-valued keys must stay JSON booleans. Storing them as strings makes
# "false" a non-empty string, which every consumer reads as TRUTHY — so a
# ticket whose replay never ran would answer "yes, replayed".
BOOLEAN_KEYS = {"replayed"}
for pair in sys.argv[2:]:
    key, _, value = pair.partition("=")
    if key in BOOLEAN_KEYS:
        ticket[key] = {"true": True, "false": False}[value]
    else:
        ticket[key] = value
tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as handle:
    json.dump(ticket, handle, indent=2)
    handle.write("\n")
os.replace(tmp, path)
' "$path" "$@"
}

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# ── read-only actions ───────────────────────────────────────────────────────
case "$ACTION" in
  list)
    found=0
    for path in "$TICKET_DIR"/*.json; do
      [ -f "$path" ] || continue
      found=1
      printf '%-28s %-12s %-28s %s\n' \
        "$(basename "$path" .json)" \
        "$(ticket_field "$path" status)" \
        "$(ticket_field "$path" skill)" \
        "$(ticket_field "$path" source)"
    done
    [ "$found" -eq 1 ] || echo "refiner-loop: no tickets"
    exit 0
    ;;
  show)
    cat "$(require_ticket "$TICKET")"
    exit 0
    ;;
esac

# ── Stage 4: Verify ─────────────────────────────────────────────────────────
if [ "$ACTION" = "verify" ]; then
  path="$(require_ticket "$TICKET")"
  status="$(ticket_field "$path" status)"
  if [ "$status" != "approved" ] && [ "$status" != "refining" ] && [ "$status" != "verified" ]; then
    echo "refiner-loop: ticket $TICKET is '$status'; Verify runs only after approval" >&2
    exit 1
  fi

  echo "── Verify"
  rc=0
  # Regenerate first: a skill edit that leaves derived artifacts stale is a
  # drift failure, not a passing fix.
  node "$REPO_ROOT/scripts/generate-skill-metadata.mjs" >/dev/null 2>&1 || rc=1
  node "$REPO_ROOT/scripts/generate-skill-evals.mjs"    >/dev/null 2>&1 || rc=1
  node "$REPO_ROOT/scripts/check-skill-contracts.mjs"   >/dev/null 2>&1 || rc=1
  bash "$REPO_ROOT/scripts/sync-harness-skills.sh" --check >/dev/null 2>&1 || rc=1

  if [ "$rc" -ne 0 ]; then
    echo "  ✗ verification gate failed"
    # Reset replayed as well: the replay never ran on this pass, and leaving a
    # stale `true` would advertise a re-execution that did not happen.
    set_fields "$path" "status=approved" "verifiedAt=" "replayed=false"
    echo "refiner-loop: FAIL — fix the gate before shipping $TICKET" >&2
    exit 1
  fi

  if ! git -C "$REPO_ROOT" diff --quiet -- \
       "$REPO_ROOT/skills" "$REPO_ROOT/evals" 2>/dev/null; then
    echo "  ✓ gate clean; skill changes staged for ship"
  else
    echo "  ✓ gate clean; no skill changes present yet"
  fi

  # ── Replay ────────────────────────────────────────────────────────────────
  # The recorded command REPRODUCED the failure when the ticket opened, so
  # after a real fix it must SUCCEED. A non-zero exit means the failure is
  # still there and no amount of green gates makes the ticket verified.
  #
  # Replay is optional: much evidence is a pasted transcript with nothing
  # runnable. When absent we SAY SO on its own line — a Verify that silently
  # checks only the gates while the skill body implies it re-ran the failure is
  # the exact defect this change closes.
  replay_cmd="$(ticket_field "$path" replay)"
  if [ -z "$replay_cmd" ]; then
    echo "  – replay: NOT RECORDED (no --replay on this ticket; the reported"
    echo "            failure was not re-executed)"
    set_fields "$path" "replayed=false"
  else
    echo "  ── replay: $replay_cmd"
    # Per-run output file: a fixed path is shared by concurrent verifies, so one
    # ticket's diagnostics could be attributed to another.
    replay_out="$(mktemp "$TICKET_DIR/.replay.XXXXXX")"
    if ( cd "$REPO_ROOT" && eval "$replay_cmd" ) >"$replay_out" 2>&1; then
      echo "  ✓ replay succeeded — the reported failure no longer reproduces"
      set_fields "$path" "replayed=true"
    else
      rc=$?
      echo "  ✗ replay FAILED (exit $rc) — the reported failure still reproduces"
      sed 's/^/      /' "$replay_out" | tail -12
      rm -f "$replay_out"
      set_fields "$path" "status=approved" "verifiedAt=" "replayed=false"
      echo "refiner-loop: FAIL — $TICKET is not fixed; replay still reproduces the failure" >&2
      exit 1
    fi
    rm -f "$replay_out"
  fi

  set_fields "$path" "status=verified" "verifiedAt=$(now)"
  echo "refiner-loop: ticket $TICKET verified"
  exit 0
fi

# ── Stage 5: Ship ───────────────────────────────────────────────────────────
if [ "$ACTION" = "ship" ]; then
  path="$(require_ticket "$TICKET")"
  status="$(ticket_field "$path" status)"
  if [ "$status" != "verified" ]; then
    echo "refiner-loop: ticket $TICKET is '$status'; Ship requires a passed Verify" >&2
    exit 1
  fi
  set_fields "$path" "status=shipped" "shippedAt=$(now)"
  echo "refiner-loop: ticket $TICKET shipped"
  exit 0
fi

# ── Triage decision: approve / reject ───────────────────────────────────────
if [ "$ACTION" = "approve" ]; then
  path="$(require_ticket "$TICKET")"
  status="$(ticket_field "$path" status)"
  if [ "$status" != "triaged" ]; then
    echo "refiner-loop: ticket $TICKET is '$status'; only a triaged ticket can be approved" >&2
    exit 1
  fi
  set_fields "$path" "status=approved" "approvedAt=$(now)"
  echo "refiner-loop: ticket $TICKET approved — Refine may proceed"
  exit 0
fi

if [ "$ACTION" = "reject" ]; then
  path="$(require_ticket "$TICKET")"
  [ -n "$REASON" ] || { echo "refiner-loop: --reject requires --reason" >&2; exit 1; }
  set_fields "$path" "status=rejected" "rejectedAt=$(now)" "rejectionReason=$REASON"
  echo "refiner-loop: ticket $TICKET rejected"
  exit 0
fi

# ── Stage 1 + 2: Detect, then Triage, then HALT ─────────────────────────────
[ -n "$SKILL" ] || { echo "refiner-loop: --skill is required" >&2; usage >&2; exit 1; }
[ -n "$EVIDENCE" ] || { echo "refiner-loop: --evidence is required (verbatim)" >&2; exit 1; }

case "$SOURCE" in
  log|sycophancy|user) : ;;
  *) echo "refiner-loop: --source must be log, sycophancy, or user" >&2; exit 1 ;;
esac

SKILL_DIR="$REPO_ROOT/skills/$SKILL"
[ -d "$SKILL_DIR" ] || { echo "refiner-loop: no such skill: $SKILL" >&2; exit 1; }

echo "── Detect"
TICKET_ID="$(date -u +%Y%m%d-%H%M%S)-$SKILL"
TICKET_FILE="$(ticket_path "$TICKET_ID")"

REFINER_SKILL="$SKILL" REFINER_SOURCE="$SOURCE" REFINER_EVIDENCE="$EVIDENCE" \
REFINER_REPLAY="$REPLAY" \
REFINER_ID="$TICKET_ID" REFINER_TS="$(now)" python3 -c '
import json, os, sys

ticket = {
    "id": os.environ["REFINER_ID"],
    "skill": os.environ["REFINER_SKILL"],
    "source": os.environ["REFINER_SOURCE"],
    "evidence": os.environ["REFINER_EVIDENCE"],
    # Optional. A command that REPRODUCED the failure when the ticket opened,
    # and that must therefore SUCCEED once the fix lands. Verify executes it.
    # Empty means no executable reproduction was recorded — Verify then says so
    # rather than implying it replayed anything.
    "replay": os.environ.get("REFINER_REPLAY", ""),
    "replayed": False,
    "detectedAt": os.environ["REFINER_TS"],
    "status": "new",
}
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(ticket, handle, indent=2)
    handle.write("\n")
' "$TICKET_FILE"
echo "  ticket $TICKET_ID opened (source: $SOURCE)"

echo ""
echo "── Triage"
# Blast radius: which other skills share trigger vocabulary with this one.
# Widening one description routinely steals prompts from a neighbour, so the
# neighbours are named here, before any edit is proposed.
DESCRIPTION="$(python3 -c '
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
body = match.group(1) if match else ""
found = re.search(r"^description:\s*(.+)$", body, re.M)
print(found.group(1).strip() if found else "")
' "$SKILL_DIR/SKILL.md")"

echo "  skill:    $SKILL"
echo "  evidence: $EVIDENCE"
echo ""
echo "  Neighbours sharing trigger vocabulary:"
NEIGHBOURS="$(REFINER_SKILL="$SKILL" REFINER_DESC="$DESCRIPTION" REFINER_ROOT="$REPO_ROOT/skills" python3 -c '
import os, re, pathlib

skill = os.environ["REFINER_SKILL"]
description = os.environ["REFINER_DESC"].lower()
words = {
    word
    for word in re.findall(r"[a-z][a-z-]{4,}", description)
    if word not in {
        "triggers", "invoke", "always", "before", "after", "when", "which",
        "these", "there", "their", "would", "should", "every", "using",
    }
}

root = pathlib.Path(os.environ.get("REFINER_ROOT", "skills"))
rows = []
for path in sorted(root.glob("*/SKILL.md")):
    name = path.parent.name
    if name == skill:
        continue
    match = re.match(r"^---\n(.*?)\n---\n", path.read_text(encoding="utf-8"), re.S)
    if not match:
        continue
    other = re.search(r"^description:\s*(.+)$", match.group(1), re.M)
    if not other:
        continue
    shared = words & set(re.findall(r"[a-z][a-z-]{4,}", other.group(1).lower()))
    if len(shared) >= 3:
        rows.append((len(shared), name, sorted(shared)[:6]))

for count, name, shared in sorted(rows, reverse=True)[:5]:
    print("    %-34s %2d shared: %s" % (name, count, ", ".join(shared)))
if not rows:
    print("    (none above threshold)")
')"
printf '%s\n' "$NEIGHBOURS"

set_fields "$TICKET_FILE" "status=triaged" "triagedAt=$(now)"

echo ""
echo "── HALT: human approval required"
cat <<HALT
  Triage produced a proposal, not a change. Nothing has been edited.

  Before approving, decide:
    - which skill actually should have fired for this input
    - whether the fault is the description (activation), the body
      (guidance), or the frontmatter (contract)
    - which neighbours above lose prompts if the triggers change

  Approve:  bash scripts/refiner-loop.sh --approve $TICKET_ID
  Reject:   bash scripts/refiner-loop.sh --reject $TICKET_ID --reason "..."
HALT
exit 0
