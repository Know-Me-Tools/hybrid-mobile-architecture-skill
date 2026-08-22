#!/usr/bin/env bash
# scripts/test-fixtures/tray-templates-negative.sh
# Negative suite for scripts/verify-tray-templates.sh.
#
# A checker that only passes is not a checker. Each fixture breaks ONE template
# in a scratch copy of the repo and asserts the gate fails naming that template.
# A positive control runs first: without it, every assertion below demands a
# non-zero exit, so a gate that can never pass would score a perfect run.
#
# SLOW: the tray fixture compiles the Tauri graph (~2min). Pass --fast to run
# only the health-aggregator fixtures.
#
# TJ-ARCH-MOB-001 compliant
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAST=0
[ "${1:-}" = "--fast" ] && FAST=1

# macOS ships no `timeout`; coreutils provides `gtimeout`. Without this the
# fixtures would fail as a false RED with rc=127 and empty output, and the
# positive control would blame the templates.
TIMEOUT=timeout
command -v timeout >/dev/null 2>&1 || TIMEOUT=gtimeout
command -v "$TIMEOUT" >/dev/null 2>&1 || {
  echo "tray-templates-negative: need coreutils timeout/gtimeout on PATH" >&2
  exit 1
}

PASS=0
FAILED=0

# run_in_copy <sed-script-over-a-template> <template-relpath> [--fast]
# Copies the repo's scripts+templates into scratch, perturbs one template,
# runs the gate there, and echoes "<rc>|<output>".
run_in_copy() {
  local perturb="$1" tpl="$2" extra="${3:-}" work out rc
  work="$(mktemp -d "${TMPDIR:-/tmp}/hma-trayneg.XXXXXX")"
  mkdir -p "$work/scripts/test-fixtures" "$work/assets"
  cp -R "$REPO_ROOT/scripts/." "$work/scripts/"
  cp -R "$REPO_ROOT/assets/templates" "$work/assets/"
  perl -0pi -e "$perturb" "$work/assets/templates/$tpl"
  out="$(cd "$work" && "$TIMEOUT" 400 bash scripts/verify-tray-templates.sh $extra 2>&1)"; rc=$?
  rm -rf "$work"
  printf '%s|%s' "$rc" "$out"
}

expect_fail() {
  local label="$1" perturb="$2" tpl="$3" needle="$4" extra="${5:-}" res rc out
  res="$(run_in_copy "$perturb" "$tpl" "$extra")"
  rc="${res%%|*}"; out="${res#*|}"
  printf '%-30s ' "$label"
  if [ "$rc" -eq 0 ]; then
    echo "FAIL — the gate PASSED on a deliberately broken template"
    FAILED=$((FAILED + 1)); return
  fi
  # rc=2 is the gate's PARTIAL (--fast skipped tray.rs), NOT a detection. Any
  # non-zero would otherwise let a skip masquerade as a caught defect.
  if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q 'PARTIAL'; then
    echo "FAIL — the gate reported PARTIAL, not a detection of the injected defect"
    FAILED=$((FAILED + 1)); return
  fi
  if ! printf '%s' "$out" | grep -qF -- "$needle"; then
    echo "FAIL — exited $rc but never named its cause (wanted: $needle)"
    printf '%s\n' "$out" | sed 's/^/      /' | tail -6
    FAILED=$((FAILED + 1)); return
  fi
  echo "ok — fails naming: $needle"
  PASS=$((PASS + 1))
}

echo "── Negative suite: verify-tray-templates.sh"
echo ""

# ── Positive control ─────────────────────────────────────────────────────────
printf '%-30s ' "POSITIVE CONTROL"
if [ "$FAST" = "1" ]; then
  ctl="$("$TIMEOUT" 200 bash "$REPO_ROOT/scripts/verify-tray-templates.sh" --fast 2>&1)"; ctl_rc=$?
else
  ctl="$("$TIMEOUT" 500 bash "$REPO_ROOT/scripts/verify-tray-templates.sh" 2>&1)"; ctl_rc=$?
fi
# Capture rc on the assignment itself: `$?` after the if/fi reports the `if`,
# not the command, so the control would never detect a failing gate.
#
# Expected rc differs by mode: a full run PASSES (0); --fast deliberately
# refuses to claim a pass and exits 2 (PARTIAL). Asserting 0 in fast mode would
# re-accept the false green this suite exists to prevent.
if [ "$FAST" = "1" ]; then want_ctl=2; else want_ctl=0; fi
if [ "$ctl_rc" -ne "$want_ctl" ]; then
  echo "FAIL — unbroken templates gave rc=$ctl_rc, expected $want_ctl"
  printf '%s\n' "$ctl" | sed 's/^/      /' | tail -8
  echo ""
  echo "tray-templates-negative: aborting — the fixtures below would be meaningless" >&2
  exit 1
fi
if [ "$FAST" = "1" ]; then
  echo "ok — unbroken templates report PARTIAL (rc=2), not a false pass"
else
  echo "ok — unbroken templates PASS"
fi
PASS=$((PASS + 1))
echo ""

# ── Fixtures ─────────────────────────────────────────────────────────────────
expect_fail "aggregator: syntax error" \
  's/pub struct/pub strct/' \
  "tauri-tray/health-aggregator/src/lib.rs.template" \
  "health-aggregator clippy failed" "--fast"

expect_fail "aggregator: failing test" \
  's/assert_eq!\(/assert_ne!(/' \
  "tauri-tray/health-aggregator/src/lib.rs.template" \
  "health-aggregator tests failed" "--fast"

if [ "$FAST" = "1" ]; then
  echo ""
  echo "  – tray.rs fixture SKIPPED (--fast). The Tauri half is the one that"
  echo "    shipped E0596; do not treat --fast as full coverage."
else
  # Reintroduce the exact bug this gate was written after: &App cannot call
  # set_activation_policy, which needs &mut App.
  expect_fail "tray.rs: reintroduce E0596" \
    's/pub fn apply_accessory_policy\(app: &mut App\)/pub fn apply_accessory_policy(app: \&App)/' \
    "tauri-tray/tray.rs.template" \
    "tray.rs does not compile"
fi

echo ""
if [ "$FAILED" -gt 0 ]; then
  echo "tray-templates-negative: $FAILED of $((PASS + FAILED)) check(s) FAILED" >&2
  exit 1
fi
if [ "$FAST" = "1" ]; then
  echo "tray-templates-negative: all $PASS check(s) behaved correctly (FAST — the tray.rs fixture was NOT run; this is not full coverage)"
else
  echo "tray-templates-negative: all $PASS check(s) behaved correctly"
fi
