#!/usr/bin/env bash
# scripts/verify-hooks-reliability.sh
# Check a project's hook chain against the 9 hook-reliability fixes.
#
# Usage:
#   bash scripts/verify-hooks-reliability.sh [target-root]   # default: repo root
#
# Exit 0 when every applicable fix holds; exit 1 naming each violated fix.
# This is the inverse of install-hooks-reliability.sh and is what a consumer's
# doctor command runs against an installed package that ships hooks.
#
# Fixes checked (see skills/claude-hooks-reliability/SKILL.md):
#   W6.1 no long inline `bash -c` bodies in hook commands
#   W6.3 no bare-string subagent matchers (must be anchored regex)
#   W6.5 hook scripts redirect diagnostics off stdout
#   W6.8 SessionStart entries are not matched with a bare wildcard
#   W6.9 every hook entry declares a matcher
#
# W6.2, W6.4, W6.6 and W6.7 are properties of a hook *runner* binary. A project
# that ships no runner has nothing to check; when a runner is present its path
# is checked for the cache, process-group kill, and NDJSON log markers.

set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ ! -d "$ROOT" ]; then
  echo "verify-hooks-reliability: not a directory: $ROOT" >&2
  exit 1
fi

VIOLATIONS=0
violation() {
  printf 'verify-hooks-reliability: %s\n' "$1" >&2
  VIOLATIONS=$((VIOLATIONS + 1))
}

# Hook configuration lives in either of these two places.
SETTINGS=""
for candidate in "$ROOT/.claude/settings.json" "$ROOT/hooks/hooks.json"; do
  if [ -f "$candidate" ]; then
    SETTINGS="$candidate"
    break
  fi
done

if [ -z "$SETTINGS" ]; then
  echo "verify-hooks-reliability: no hook configuration at $ROOT (nothing to check)"
  exit 0
fi

if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$SETTINGS" >/dev/null 2>&1; then
  violation "hook configuration is not valid JSON: $SETTINGS"
  echo "verify-hooks-reliability: FAIL (1 violation)" >&2
  exit 1
fi

# Emit one "<event>\t<matcher-or-@none>\t<command>" line per hook entry so the
# shell can check each fix without re-parsing JSON per rule.
ENTRIES="$(python3 -c '
import json, sys
doc = json.load(open(sys.argv[1]))
hooks = doc.get("hooks", doc) or {}
for event, entries in hooks.items():
    if not isinstance(entries, list):
        continue
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        matcher = entry.get("matcher")
        matcher = "@none" if matcher is None else str(matcher)
        commands = entry.get("hooks") or []
        if not commands:
            print("\t".join([event, matcher, ""]))
        for command in commands:
            text = (command or {}).get("command", "")
            print("\t".join([event, matcher, text.replace("\t", " ").replace("\n", " ")]))
' "$SETTINGS")"

while IFS="$(printf '\t')" read -r event matcher command; do
  [ -n "$event" ] || continue

  # W6.9 — every entry declares a matcher, even a wildcard.
  if [ "$matcher" = "@none" ]; then
    violation "W6.9: $event entry has no matcher field (add \"matcher\": \"*\")"
  fi

  # W6.8 — SessionStart must not fire on a bare wildcard.
  if [ "$event" = "SessionStart" ] && { [ "$matcher" = "*" ] || [ "$matcher" = "@none" ]; }; then
    violation "W6.8: SessionStart matcher is a bare wildcard; narrow it to the consuming harness"
  fi

  # W6.3 — subagent matchers must be anchored regex, not a bare name.
  if [ "$event" = "SubagentStop" ] && [ "$matcher" != "@none" ] && [ "$matcher" != "*" ]; then
    case "$matcher" in
      \^*\$) : ;;
      *) violation "W6.3: SubagentStop matcher '$matcher' is a bare string; anchor it as ^(...)\$" ;;
    esac
  fi

  # W6.1 — no long inline bash -c script bodies.
  case "$command" in
    *"bash -c"*|*"sh -c"*)
      if [ "${#command}" -gt 120 ]; then
        violation "W6.1: $event has an inline shell body of ${#command} chars; extract it to a script file"
      fi
      ;;
  esac
done <<EOF_ENTRIES
$ENTRIES
EOF_ENTRIES

# W6.5 — every hook script must send diagnostics somewhere other than stdout,
# because stdout is parsed as the hook's decision payload.
if [ -d "$ROOT/.claude/hooks" ]; then
  for script in "$ROOT"/.claude/hooks/*; do
    [ -f "$script" ] || continue
    case "$script" in
      *.sh)
        grep -q 'exec 2>' "$script" \
          || violation "W6.5: $(basename "$script") does not redirect stderr away from stdout (add 'exec 2>>\"\$LOG\"')"
        ;;
      *.py)
        # W6.5 forbids *diagnostics* on stdout, not the decision payload — a
        # hook writing its JSON result to stdout is correct. Flag only bare
        # human-readable prints, i.e. a print() whose argument is a string
        # literal rather than serialized JSON.
        if grep -Eq '^[^#]*print\(\s*(f?["'"'"'])' "$script"; then
          violation "W6.5: $(basename "$script") prints a plain string to stdout; diagnostics belong on stderr"
        fi
        ;;
    esac
  done
fi

# W6.2 / W6.4 / W6.6 — runner properties, checked only when a runner exists.
RUNNER=""
for candidate in "$ROOT/shared/scripts/run-hook" "$ROOT/scripts/run-hook"; do
  [ -f "$candidate" ] && RUNNER="$candidate" && break
done
if [ -n "$RUNNER" ]; then
  grep -q 'shasum\|sha256sum' "$RUNNER" && ! grep -q 'cache\|CACHE' "$RUNNER" \
    && violation "W6.2: $RUNNER re-hashes the dispatcher with no cache window"
  grep -q 'setsid\|setpgid' "$RUNNER" \
    || violation "W6.4: $RUNNER does not spawn hooks in their own process group; timeouts will leak children"
  grep -q 'hooks.ndjson' "$RUNNER" \
    || violation "W6.6: $RUNNER writes no structured per-invocation hook log"
fi

if [ "$VIOLATIONS" -ne 0 ]; then
  echo "verify-hooks-reliability: FAIL ($VIOLATIONS violation(s)) at $ROOT" >&2
  exit 1
fi

echo "verify-hooks-reliability: PASS ($SETTINGS)"
