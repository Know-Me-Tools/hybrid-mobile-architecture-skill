#!/usr/bin/env bash
# scripts/test-fixtures/w6-mapping-negative.sh
# Negative suite for scripts/check-w6-mapping.sh.
#
# A positive control runs first: every assertion below demands a non-zero exit,
# so a check that can never pass would otherwise score a perfect run.
#
# TJ-ARCH-MOB-001 compliant
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PASS=0
FAILED=0

# perturb <perl-expr> <repo-relative-file> <needle>
perturb() {
  local label="$1" expr="$2" rel="$3" needle="$4" work out rc
  work="$(mktemp -d "${TMPDIR:-/tmp}/hma-w6neg.XXXXXX")"
  mkdir -p "$work/scripts/test-fixtures" "$work/docs" "$work/skills"
  cp -R "$REPO_ROOT/scripts/." "$work/scripts/"
  cp -R "$REPO_ROOT/docs/." "$work/docs/" 2>/dev/null
  cp -R "$REPO_ROOT/skills/." "$work/skills/" 2>/dev/null
  perl -0pi -e "$expr" "$work/$rel"
  out="$(cd "$work" && bash scripts/check-w6-mapping.sh 2>&1)"; rc=$?
  rm -rf "$work"
  printf '%-34s ' "$label"
  if [ "$rc" -eq 0 ]; then
    echo "FAIL — the check PASSED on a deliberately broken mapping"
    FAILED=$((FAILED + 1)); return
  fi
  if ! printf '%s' "$out" | grep -qF -- "$needle"; then
    echo "FAIL — exited $rc but never named its cause (wanted: $needle)"
    printf '%s\n' "$out" | sed 's/^/      /' | tail -5
    FAILED=$((FAILED + 1)); return
  fi
  echo "ok — fails naming: $needle"
  PASS=$((PASS + 1))
}

echo "── Negative suite: check-w6-mapping.sh"
echo ""

printf '%-34s ' "POSITIVE CONTROL"
if bash "$REPO_ROOT/scripts/check-w6-mapping.sh" >/dev/null 2>&1; then
  echo "ok — the real tree PASSES"
  PASS=$((PASS + 1))
else
  echo "FAIL — the check does not pass on the unmodified tree"
  bash "$REPO_ROOT/scripts/check-w6-mapping.sh" 2>&1 | sed 's/^/      /' | tail -6
  echo ""
  echo "w6-mapping-negative: aborting — the fixtures below would be meaningless" >&2
  exit 1
fi
echo ""

# Swap two labels in the SHIPPED skill: the classic offset that started this.
perturb "skill: swap W6.4 and W6.5" \
  's/### W6\.4 — Hook stdout/### W6.X — Hook stdout/; s/### W6\.5 — Hooks leak/### W6.4 — Hooks leak/; s/### W6\.X — Hook stdout/### W6.5 — Hook stdout/' \
  "skills/claude-hooks-reliability/SKILL.md" \
  "should be the 'stdout' weakness"

# Same drift in the spec.
perturb "docs/03: W6.9 renamed" \
  's/### W6\.9 — Inline `bash -c` is unfixable long-term/### W6.9 — Something unrelated entirely/' \
  "docs/03-hooks-reliability.md" \
  "should be the 'interpreter|unfixable' weakness"

# Regression to the original defect: W-numbers back in the remedy table.
perturb "docs/05: R6.8 back to W6.8" \
  's/^\| R6\.8 \|/| W6.8 |/m' \
  "docs/05-hma-pmp-companion-architecture.md" \
  "must use R6.x"

# Retarget one weakness's remedy onto another's. Both numbers still EXIST in
# docs/05, so an existence-only check passes — this is the case that exposed
# the need for the cite-exactly-once assertion.
perturb "docs/03: two weaknesses, one R6.x" \
  's/\*\*Fix \(R6\.7\)/**Fix (R6.6)/' \
  "docs/03-hooks-reliability.md" \
  "R6.x cited by more than one weakness"

# A citation with no row at all.
perturb "docs/03 cites a nonexistent R6.x" \
  's/\*\*Fix \(R6\.7\)/**Fix (R6.0)/' \
  "docs/03-hooks-reliability.md" \
  "no such row"

# A W6.9-shaped heading placed at slot 1. An earlier keyword ("inline") matched
# both, so this passed — the check validated numbers, not meaning.
perturb "docs/03: W6.9 heading at slot 1" \
  's/### W6\.1 — Inline `bash -c .….` is fragile/### W6.1 — Inline `bash -c` is unfixable long-term/' \
  "docs/03-hooks-reliability.md" \
  "W6.1 should be the"

# Swap two remedy rows' CONTENT while leaving both numbers present: every
# citation still resolves, so a number-only check cannot see it.
perturb "docs/05: R6.4/R6.7 content swap" \
  'BEGIN{undef $/} s/^\| R6\.4 \| Use process-group kill in the hook runner \|/| R6.4 | Add a 1-line structured hook-result log to `hooks.ndjson` |/m' \
  "docs/05-hma-pmp-companion-architecture.md" \
  "R6.4 should be the"

echo ""
if [ "$FAILED" -gt 0 ]; then
  echo "w6-mapping-negative: $FAILED of $((PASS + FAILED)) check(s) FAILED" >&2
  exit 1
fi
echo "w6-mapping-negative: all $PASS check(s) behaved correctly"
