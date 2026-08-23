#!/usr/bin/env bash
# scripts/run-all-gates.sh
# Run every local gate and report one verdict.
#
# WHY THIS EXISTS
#   "All gates green" was prose. The phase's own assessment claimed "9 of 10"
#   from a hand-maintained table that omitted `check-git-url-discovery.sh` —
#   which was RED on clean HEAD at the time. A count you reconstruct by reading
#   is a count that drifts; this script is the enumeration.
#
# USAGE
#   bash scripts/run-all-gates.sh            # every gate
#   bash scripts/run-all-gates.sh --fast     # skip the slow build gates
#   bash scripts/run-all-gates.sh --list     # print the roster, run nothing
#
# SLOW GATES
#   tray-templates renders and builds the Tauri graph (~2min) and consumer-install
#   clones the package (~1min). --fast skips them and, like the gates it wraps,
#   refuses to report a pass: it exits 2 PARTIAL rather than claiming coverage
#   it does not have.
#
# TJ-ARCH-MOB-001 compliant
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

FAST=0
LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --fast) FAST=1; shift ;;
    --list) LIST=1; shift ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "run-all-gates: unknown option: $1" >&2; exit 1 ;;
  esac
done

# name|slow|command
GATES=(
  "check-builder-authority|0|node scripts/check-builder-authority.mjs --release"
  "check-skill-contracts|0|node scripts/check-skill-contracts.mjs"
  "check-prometheus-boundary|0|node scripts/check-prometheus-boundary.mjs"
  "check-runtime-security|0|node scripts/check-runtime-security.mjs"
  "check-git-url-discovery|0|bash scripts/check-git-url-discovery.sh"
  "check-w6-mapping|0|bash scripts/check-w6-mapping.sh"
  "sync-harness-skills|0|bash scripts/sync-harness-skills.sh --check"
  "sync-skill-resources|0|node scripts/sync-skill-resources.mjs --check"
  "audit:doc-consistency|0|bash scripts/audit.sh doc-consistency"
  "audit:generator-purity|0|bash scripts/audit.sh generator-purity"
  "verify-skill-manifest|0|bash scripts/verify-skill-manifest.sh"
  "verify-hooks-reliability|0|bash scripts/verify-hooks-reliability.sh"
  "normalize-vendored-skills|0|bash scripts/normalize-vendored-skills.sh --check"
  "test-harness-installer|1|bash scripts/test-harness-installer.sh"
  "verify-tray-templates|1|bash scripts/verify-tray-templates.sh"
  "test-consumer-install|1|bash scripts/test-consumer-install.sh"
)

if [ "$LIST" = "1" ]; then
  printf '%-28s %s\n' "GATE" "COST"
  for g in "${GATES[@]}"; do
    IFS='|' read -r name slow _ <<< "$g"
    printf '%-28s %s\n' "$name" "$([ "$slow" = "1" ] && echo slow || echo fast)"
  done
  echo ""
  echo "${#GATES[@]} gates"
  exit 0
fi

PASSED=0
FAILED=0
SKIPPED=0
FAILED_NAMES=""
LOG="$(mktemp -d "${TMPDIR:-/tmp}/hma-gates.XXXXXX")"
trap 'rm -rf "$LOG"' EXIT

echo "── Local gate suite (${#GATES[@]} gates)"
echo ""

for g in "${GATES[@]}"; do
  IFS='|' read -r name slow cmd <<< "$g"
  if [ "$FAST" = "1" ] && [ "$slow" = "1" ]; then
    printf '  %-28s SKIP (--fast)\n' "$name"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  printf '  %-28s ' "$name"
  if eval "$cmd" >"$LOG/$name.out" 2>&1; then
    echo "PASS"
    PASSED=$((PASSED + 1))
  else
    rc=$?
    echo "FAIL (exit $rc)"
    FAILED=$((FAILED + 1))
    FAILED_NAMES="$FAILED_NAMES $name"
    tail -6 "$LOG/$name.out" | sed 's/^/        /'
  fi
done

echo ""
if [ "$FAILED" -gt 0 ]; then
  echo "run-all-gates: FAIL — $FAILED of $((PASSED + FAILED)) run gate(s) failed:$FAILED_NAMES" >&2
  exit 1
fi
if [ "$SKIPPED" -gt 0 ]; then
  # Mirror the slow gates' own contract: a partial run never claims a pass.
  echo "run-all-gates: PARTIAL — $PASSED passed, $SKIPPED skipped (--fast). This is not a pass." >&2
  exit 2
fi
echo "run-all-gates: PASS — all $PASSED gates green"
