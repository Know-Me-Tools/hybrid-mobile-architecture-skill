#!/usr/bin/env bash
# scripts/install-hooks-reliability.sh
# Apply the mechanically-applicable hook-reliability fixes to a target project.
#
# Usage:
#   bash scripts/install-hooks-reliability.sh [target-root]   # default: repo root
#   bash scripts/install-hooks-reliability.sh --dry-run [target-root]
#
# Idempotent: re-running on a fixed tree changes nothing and exits 0.
# Verify the result with scripts/verify-hooks-reliability.sh.
#
# Applied automatically:
#   W6.8  add an explicit matcher to every hook entry that lacks one
#   W6.6  narrow a bare-wildcard SessionStart matcher to the harness
#   W6.3  anchor bare-string SubagentStop matchers as ^(name)$
#
# Reported but NOT auto-applied (each needs a human decision about behavior):
#   W6.1  extracting an inline shell body to a script file
#   W6.2  the runner's dispatcher-hash cache window
#   W6.5  process-group spawn and zombie reaping in the runner
#   W6.4  moving diagnostics off stdout in a hook script
#   W6.7  the structured NDJSON hook log
#   W6.9  replacing the inline bash interpreter with a dispatcher binary

set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ ! -d "$ROOT" ]; then
  echo "install-hooks-reliability: not a directory: $ROOT" >&2
  exit 1
fi

SETTINGS=""
for candidate in "$ROOT/.claude/settings.json" "$ROOT/hooks/hooks.json"; do
  if [ -f "$candidate" ]; then
    SETTINGS="$candidate"
    break
  fi
done

if [ -z "$SETTINGS" ]; then
  echo "install-hooks-reliability: no hook configuration at $ROOT (nothing to apply)"
  exit 0
fi

if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$SETTINGS" >/dev/null 2>&1; then
  echo "install-hooks-reliability: hook configuration is not valid JSON: $SETTINGS" >&2
  exit 1
fi

# Rewrite the matcher-level fixes in place, preserving key order and any keys
# this script does not understand. Writes only when something actually changed.
CHANGED="$(DRY_RUN="$DRY_RUN" python3 -c '
import json, os, re, sys

path = sys.argv[1]
dry_run = os.environ.get("DRY_RUN") == "1"

with open(path, encoding="utf-8") as handle:
    original = handle.read()
doc = json.loads(original)

hooks = doc.get("hooks")
container = doc if hooks is None else doc["hooks"]
hooks = container if hooks is None else hooks

applied = []
for event, entries in (hooks or {}).items():
    if not isinstance(entries, list):
        continue
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        matcher = entry.get("matcher")

        # W6.8 — an entry with no matcher is unconditional and silently
        # double-fires the moment a sibling entry is added.
        if matcher is None:
            chosen = "claude-code" if event == "SessionStart" else "*"
            entry["matcher"] = chosen
            applied.append("W6.8: %s: added matcher %r" % (event, chosen))
            matcher = chosen

        # W6.6 — a bare wildcard SessionStart pays cold-start cost on every
        # session, including ones that never use the hook.
        if event == "SessionStart" and matcher == "*":
            entry["matcher"] = "claude-code"
            applied.append("W6.6: SessionStart: narrowed matcher \"*\" -> \"claude-code\"")
            matcher = entry["matcher"]

        # W6.3 — a bare-string subagent matcher matches exactly one name and
        # silently stops firing when the agent is renamed.
        if event == "SubagentStop" and isinstance(matcher, str) \
                and matcher not in ("*",) \
                and not (matcher.startswith("^") and matcher.endswith("$")):
            anchored = "^(" + re.escape(matcher) + ")$"
            entry["matcher"] = anchored
            applied.append(f"W6.3: SubagentStop: anchored matcher -> {anchored!r}")

if applied and not dry_run:
    trailing = "\n" if original.endswith("\n") else ""
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        handle.write(json.dumps(doc, indent=2) + trailing)
    os.replace(tmp, path)

print("\n".join(applied))
' "$SETTINGS")"

if [ -n "$CHANGED" ]; then
  printf '%s\n' "$CHANGED" | while IFS= read -r line; do
    [ -n "$line" ] && printf '  applied  %s\n' "$line"
  done
else
  echo "  no matcher fixes needed"
fi

# Report the fixes that require a human decision rather than editing behavior.
ADVISORY=0
advise() {
  printf '  review   %s\n' "$1"
  ADVISORY=$((ADVISORY + 1))
}

while IFS="$(printf '\t')" read -r event command; do
  [ -n "$event" ] || continue
  case "$command" in
    *"bash -c"*|*"sh -c"*)
      if [ "${#command}" -gt 120 ]; then
        advise "W6.1: $event has a ${#command}-char inline shell body; extract it to a script file"
      fi
      ;;
  esac
done <<EOF_CMDS
$(python3 -c '
import json, sys
doc = json.load(open(sys.argv[1]))
hooks = doc.get("hooks", doc) or {}
for event, entries in hooks.items():
    if not isinstance(entries, list):
        continue
    for entry in entries:
        for command in (entry.get("hooks") or []):
            text = (command or {}).get("command", "")
            print("\t".join([event, text.replace("\t", " ").replace("\n", " ")]))
' "$SETTINGS")
EOF_CMDS

if [ -d "$ROOT/.claude/hooks" ]; then
  for script in "$ROOT"/.claude/hooks/*; do
    [ -f "$script" ] || continue
    case "$script" in
      *.sh)
        grep -q 'exec 2>' "$script" \
          || advise "W6.4: $(basename "$script") should redirect stderr before doing work"
        ;;
      *.py)
        grep -Eq '^[^#]*print\(\s*(f?["'"'"'])' "$script" \
          && advise "W6.4: $(basename "$script") prints a plain string to stdout; move diagnostics to stderr"
        ;;
    esac
  done
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "install-hooks-reliability: DRY RUN, no files written ($SETTINGS)"
else
  echo "install-hooks-reliability: done ($SETTINGS)"
fi
if [ "$ADVISORY" -gt 0 ]; then
  echo "install-hooks-reliability: $ADVISORY fix(es) need a human decision; see the messages above"
fi
