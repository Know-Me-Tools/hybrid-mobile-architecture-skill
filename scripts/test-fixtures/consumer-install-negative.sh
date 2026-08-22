#!/usr/bin/env bash
# scripts/test-fixtures/consumer-install-negative.sh
# Negative suite for scripts/test-consumer-install.sh.
#
# A checker that only passes is not a checker. Each fixture breaks the clone in
# ONE documented way and asserts the proof fails AND names that specific cause —
# not merely that it exited non-zero, which any crash would satisfy.
#
# TJ-ARCH-MOB-001 compliant
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROOF="$REPO_ROOT/scripts/test-consumer-install.sh"
PASS=0
FAILED=0

# Clone once and share it. Each proof run copies this pristine tree, so every
# fixture still mutates its own; we just do not pay for five git clones.
SHARED="$(mktemp -d "${TMPDIR:-/tmp}/hma-neg.XXXXXX")"
trap 'rm -rf "$SHARED"' EXIT
git clone --quiet --no-local "$REPO_ROOT" "$SHARED/pristine" 2>/dev/null || {
  echo "consumer-install-negative: could not clone the package" >&2; exit 1; }
export CONSUMER_INSTALL_REUSE_CLONE="$SHARED/pristine"

# expect <fixture> <substring the failure message must contain> [full-contract]
# Without `full-contract` the ~37s contract verifier is skipped — use it only
# for fixtures whose failure the contract itself must report.
#
# The match is anchored to the proof's OWN failure prefixes. An unanchored
# grep over combined output accepted the fixture banner echoing its own name,
# and could not tell a genuine detection from collateral breakage.
expect() {
  local fixture="$1" needle="$2" mode="${3:-fast}" out rc
  if [ "$mode" = "full-contract" ]; then
    out="$(CONSUMER_INSTALL_FIXTURE="$fixture" bash "$PROOF" 2>&1)"; rc=$?
  else
    out="$(CONSUMER_INSTALL_FIXTURE="$fixture" CONSUMER_INSTALL_SKIP_CONTRACT=1 bash "$PROOF" 2>&1)"; rc=$?
  fi
  printf '%-28s ' "$fixture"
  if [ "$rc" -eq 0 ]; then
    echo "FAIL — the proof PASSED on a deliberately broken package"
    FAILED=$((FAILED + 1)); return
  fi
  if [ "$rc" -ge 2 ]; then
    echo "FAIL — the proof CRASHED (exit $rc) rather than detecting the defect"
    printf '%s\n' "$out" | sed 's/^/      /' | tail -4
    FAILED=$((FAILED + 1)); return
  fi
  # Only lines the proof itself emits as failures count as a detection.
  if ! printf '%s' "$out" \
       | grep -E '^(test-consumer-install: FAIL:|      verify-skill-manifest:|verify-skill-manifest:)' \
       | grep -qF -- "$needle"; then
    echo "FAIL — exited $rc but no failure line named its cause (wanted: $needle)"
    printf '%s\n' "$out" | sed 's/^/      /' | tail -6
    FAILED=$((FAILED + 1)); return
  fi
  echo "ok — fails naming: $needle"
  PASS=$((PASS + 1))
}

echo "── Negative suite: test-consumer-install.sh"
echo ""

# ── Positive control — MUST come first ───────────────────────────────────────
# Without this, every assertion below demands a non-zero exit, so a proof that
# ALWAYS fails scores a perfect 5/5. A 6-line stub that reads no input and
# prints all five needles did exactly that against an earlier revision of this
# suite. This control is the only assertion that distinguishes a real checker
# from one that cannot pass.
printf '%-28s ' "POSITIVE CONTROL"
control_out="$(CONSUMER_INSTALL_SKIP_CONTRACT=1 CONSUMER_INSTALL_FIXTURE="" bash "$PROOF" 2>&1)"
control_rc=$?
if [ "$control_rc" -ne 0 ]; then
  echo "FAIL — the proof does not pass on an UNBROKEN package (exit $control_rc)"
  printf '%s\n' "$control_out" | sed 's/^/      /' | tail -6
  echo ""
  echo "consumer-install-negative: aborting — the fixtures below would be meaningless" >&2
  exit 1
fi
if ! printf '%s' "$control_out" | grep -q 'test-consumer-install: PASS'; then
  echo "FAIL — exit 0 but no PASS line; the proof is not reporting a real result"
  FAILED=$((FAILED + 1))
else
  echo "ok — an unbroken package PASSES"
  PASS=$((PASS + 1))
fi
echo ""

# 1.4 — an undeclared skill directory ships to nobody and is invisible.
expect undeclared-skill "not declared in the registry: rogue-undeclared-skill" full-contract

# 1.5 — without plugin.json the harness has nothing to register.
expect missing-plugin-json "C2: missing plugin.json at package root" full-contract

# 1.6 — a registry entry that resolves to nothing is a broken promise.
expect unresolvable-skill "resolves to no SKILL.md"

# Bonus: a resolvable file whose frontmatter names a different skill resolves
# to the WRONG skill — file existence would have accepted this.
expect frontmatter-name-mismatch "frontmatter name is 'not-the-directory-name'"

# Bonus: a skill that resolves but is absent from the harness mirror installs
# and then never fires.
expect missing-harness-mirror ".claude/skills is missing: realtime-skill-refiner"

echo ""
if [ "$FAILED" -gt 0 ]; then
  echo "consumer-install-negative: $FAILED of $((PASS + FAILED)) fixture(s) FAILED" >&2
  exit 1
fi
echo "consumer-install-negative: all $PASS fixture(s) fail for their own stated reason"
