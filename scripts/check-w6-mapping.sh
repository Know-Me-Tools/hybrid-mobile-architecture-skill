#!/usr/bin/env bash
# scripts/check-w6-mapping.sh
# Freeze the hook-weakness (W6.x) and hook-remedy (R6.x) indices so they cannot
# drift apart again.
#
# WHY THIS EXISTS
#   Four sequences had diverged: the architecture review §6 (the source of
#   truth docs/03 names), docs/03's own headings, the SHIPPED
#   claude-hooks-reliability skill, and a table in docs/05 that used W-numbers
#   for what were actually remedies. Both W6.7 and W6.8 meant different things
#   in different files, so no single-label edit could reconcile them.
#
#   c304 aligned all three local artifacts to the review and relabelled the
#   docs/05 table R6.x, which is what it always was. This check keeps them there.
#
# CHECKS
#   1. docs/03 and the shipped skill declare the same W6.N -> topic mapping
#   2. both are numerically ordered with no gaps or duplicates
#   3. every R6.N cited by docs/03 resolves to the same remedy row in docs/05
#   4. the docs/05 table uses R-numbers, not W-numbers
#
# TJ-ARCH-MOB-001 compliant
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$REPO_ROOT/docs/03-hooks-reliability.md"
SKILL="$REPO_ROOT/skills/claude-hooks-reliability/SKILL.md"
ARCH="$REPO_ROOT/docs/05-hma-pmp-companion-architecture.md"

FAILURES=0
fail() { printf 'check-w6-mapping: %s\n' "$1" >&2; FAILURES=$((FAILURES + 1)); }

for f in "$SPEC" "$SKILL" "$ARCH"; do
  [ -f "$f" ] || { fail "missing ${f#"$REPO_ROOT"/}"; exit 1; }
done

# Topic keywords per canonical W6.N, from the architecture review §6. Matching on
# a keyword rather than the full heading lets each document phrase its own
# heading while still pinning WHICH weakness the number denotes.
# Keywords must be MUTUALLY EXCLUSIVE. A bare "inline" for W6.1 also matched
# W6.9's "Inline `bash -c` is unfixable long-term", so a W6.9 heading placed at
# slot 1 passed. The no-multi-match assertion below enforces exclusivity so a
# future keyword edit cannot silently reintroduce the overlap.
topic_for() {
  case "$1" in
    1) echo "inline .bash -c[^|]*fragile" ;;
    2) echo "sha" ;;
    3) echo "subagent" ;;    4) echo "stdout" ;;
    5) echo "leak" ;;        6) echo "sessionstart" ;;
    7) echo "structured" ;;  8) echo "userpromptsubmit" ;;
    9) echo "interpreter|unfixable" ;;
    *) echo "" ;;
  esac
}

# Remedy keywords for the docs/05 table. Number-only validation let the row
# CONTENTS be swapped while every citation still resolved.
remedy_for() {
  case "$1" in
    1) echo "extracted scripts" ;;      2) echo "compile .run-hook" ;;
    3) echo "cache" ;;                  4) echo "process-group" ;;
    5) echo "regex-anchored" ;;         6) echo "exec 2" ;;
    7) echo "ndjson|structured" ;;      8) echo "rust binary" ;;
    9) echo "tighten" ;;
    *) echo "" ;;
  esac
}

# heading_for <file> <n> — the W6.N heading text, lowercased
heading_for() {
  grep -m1 -i "^### W6\.$2 " "$1" 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

echo "── W6.x / R6.x mapping"

for n in 1 2 3 4 5 6 7 8 9; do
  want="$(topic_for "$n")"
  for f in "$SPEC" "$SKILL"; do
    label="${f#"$REPO_ROOT"/}"
    head="$(heading_for "$f" "$n")"
    if [ -z "$head" ]; then
      fail "$label: no W6.$n section"
      continue
    fi
    if ! printf '%s' "$head" | grep -qE "$want"; then
      fail "$label: W6.$n should be the '$want' weakness, found: ${head#\#\#\# }"
    fi
  done
done

# No duplicates, no gaps.
for f in "$SPEC" "$SKILL"; do
  label="${f#"$REPO_ROOT"/}"
  nums="$(grep -o '^### W6\.[0-9]' "$f" | grep -o '[0-9]$' | tr '\n' ' ')"
  sorted="$(printf '%s\n' $nums | sort -n | tr '\n' ' ')"
  [ "$nums" = "$sorted" ] || fail "$label: W6.x sections are out of order: $nums"
  dupes="$(printf '%s\n' $nums | sort | uniq -d | tr '\n' ' ')"
  [ -z "$dupes" ] || fail "$label: duplicate W6.x labels: $dupes"
  [ "$(printf '%s\n' $nums | sort -u | wc -l | tr -d ' ')" = "9" ] \
    || fail "$label: expected 9 distinct W6.x sections, found $(printf '%s\n' $nums | sort -u | wc -l | tr -d ' ')"
done

# The docs/05 table indexes REMEDIES. A W-number there is the original bug.
if grep -qE '^\| W6\.[0-9] \|' "$ARCH"; then
  fail "docs/05: the remedy table uses W6.x labels; it indexes remedies and must use R6.x"
fi

# Every R6.N docs/03 cites must exist in docs/05's table...
for r in $(grep -o 'Fix (R6\.[0-9])' "$SPEC" | sed 's/.*R6\.//; s/)//' | sort -u); do
  grep -qE "^\| R6\.$r \|" "$ARCH" \
    || fail "docs/03 cites R6.$r but docs/05's remedy table has no such row"
done

# ...and must cite it exactly ONCE. Existence alone is too weak: retargeting a
# section from R6.7 to R6.6 leaves both numbers valid, so the mapping silently
# breaks while every citation still resolves. A duplicate means two weaknesses
# claim one remedy.
dupe_r="$(grep -o 'Fix (R6\.[0-9])' "$SPEC" | sed 's/.*R6\.//; s/)//' | sort | uniq -d | tr '\n' ' ')"
[ -z "$dupe_r" ] || fail "docs/03: R6.x cited by more than one weakness: $dupe_r"

# No heading may satisfy two different topic keywords — that ambiguity is what
# let a wrong heading pass at slot 1.
for f in "$SPEC" "$SKILL"; do
  label="${f#"$REPO_ROOT"/}"
  for n in 1 2 3 4 5 6 7 8 9; do
    head="$(heading_for "$f" "$n")"
    [ -n "$head" ] || continue
    hits=""
    for m in 1 2 3 4 5 6 7 8 9; do
      printf '%s' "$head" | grep -qE "$(topic_for "$m")" && hits="$hits $m"
    done
    set -- $hits
    [ "$#" -le 1 ] || fail "$label: the W6.$n heading matches topics$hits — keywords must be unambiguous"
  done
done

# Each docs/05 remedy row must SAY the remedy its number denotes.
for n in 1 2 3 4 5 6 7 8 9; do
  row="$(grep -m1 -i "^| R6\.$n |" "$ARCH" | tr '[:upper:]' '[:lower:]')"
  if [ -z "$row" ]; then
    fail "docs/05: no R6.$n row"
    continue
  fi
  want="$(remedy_for "$n")"
  printf '%s' "$row" | grep -qE "$want" \
    || fail "docs/05: R6.$n should be the '$want' remedy, found: $(printf '%s' "$row" | cut -d'|' -f3 | cut -c1-46)"
done

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "check-w6-mapping: FAIL — $FAILURES mapping problem(s)" >&2
  exit 1
fi
echo "check-w6-mapping: PASS — W6.1-W6.9 agree across docs/03 and the shipped skill; every cited R6.x resolves in docs/05"
