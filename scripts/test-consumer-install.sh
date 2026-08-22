#!/usr/bin/env bash
# scripts/test-consumer-install.sh
# Prove the install contract from a CONSUMER's position, not the author's.
#
# WHY THIS EXISTS
#   The prior phase's smoke test proved this repo's own scripts run from a
#   clone. That is a weaker claim than it sounds: it never established that a
#   third party can take the package and register its skills. This script does.
#
#   It clones the package to a scratch location and exercises the documented
#   contract there. Nothing reads the source working tree — a passing result
#   cannot be produced by the checkout you are sitting in.
#
# USAGE
#   bash scripts/test-consumer-install.sh              # clone HEAD of this repo
#   bash scripts/test-consumer-install.sh --ref v2.0.0-alpha.3
#   bash scripts/test-consumer-install.sh --keep       # leave the clone for inspection
#
# EXIT
#   0  a consumer following the documented contract gets all skills
#   1  the contract is broken; every failure is named
#
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

SOURCE_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REF="HEAD"
KEEP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --ref)  REF="${2:?--ref needs a value}"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "test-consumer-install: unknown option: $1" >&2; exit 1 ;;
  esac
done

# The skills a consumer of HMA v0.2.0 must receive. Hardcoded ON PURPOSE:
# deriving this list from the package under test would make the assertion
# circular — a package that shipped zero skills would "pass" by declaring zero.
readonly REQUIRED_SKILLS=(
  connected-skill-packages
  claude-hooks-reliability
  realtime-skill-refiner
  tauri-tray-app
  launchagent-supervisor
  auto-skill-package-integration
)

FAILURES=0
fail() { printf 'test-consumer-install: FAIL: %s\n' "$1" >&2; FAILURES=$((FAILURES + 1)); }
ok()   { printf '  ✓ %s\n' "$1"; }

# CONSUMER_INSTALL_REUSE_CLONE lets the negative suite hand us a pristine clone
# it already made, so five fixtures do not pay for five clones. The proof still
# copies it per run, so each fixture mutates its own tree.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/hma-consumer.XXXXXX")"
cleanup() {
  if [ "$KEEP" = "1" ]; then
    echo "test-consumer-install: clone kept at $WORK"
  else
    rm -rf "$WORK"
  fi
}
trap cleanup EXIT

CLONE="$WORK/package"

echo "── Consumer install proof"
echo "   source: $SOURCE_REPO ($REF)"
echo "   clone:  $CLONE"
echo ""

# ── Step 1: clone, the way a consumer installs ───────────────────────────────
# `connected-skill-packages` documents git clone as the install mechanism.
if [ -n "${CONSUMER_INSTALL_REUSE_CLONE:-}" ]; then
  # A handed-in tree is only acceptable if it is a PRISTINE CLONE. Accepting it
  # unchecked let a caller point this at the live source tree and get a PASS —
  # precisely the circularity this script exists to rule out, and the path
  # assertion below could not catch it because it only inspects $WORK.
  REUSE="$CONSUMER_INSTALL_REUSE_CLONE"
  [ -d "$REUSE" ] || { fail "CONSUMER_INSTALL_REUSE_CLONE is not a directory: $REUSE"; exit 1; }
  git -C "$REUSE" rev-parse --git-dir >/dev/null 2>&1 \
    || { fail "CONSUMER_INSTALL_REUSE_CLONE is not a git repository: $REUSE"; exit 1; }
  if [ "$(cd "$REUSE" && pwd -P)" = "$(cd "$SOURCE_REPO" && pwd -P)" ]; then
    fail "CONSUMER_INSTALL_REUSE_CLONE points at the source tree — the proof would be circular"
    exit 1
  fi
  if [ -n "$(git -C "$REUSE" status --porcelain 2>/dev/null)" ]; then
    fail "CONSUMER_INSTALL_REUSE_CLONE has uncommitted changes; a consumer receives committed content only"
    exit 1
  fi
  cp -R "$REUSE" "$CLONE"
  REUSED=1
elif ! git clone --quiet --no-local "$SOURCE_REPO" "$CLONE" 2>"$WORK/clone.err"; then
  fail "git clone failed: $(tr '\n' ' ' < "$WORK/clone.err")"
  exit 1
fi
if ! git -C "$CLONE" checkout --quiet "$REF" 2>"$WORK/checkout.err"; then
  fail "cannot check out ref '$REF': $(tr '\n' ' ' < "$WORK/checkout.err")"
  exit 1
fi
RESOLVED="$(git -C "$CLONE" rev-parse --short HEAD 2>/dev/null || echo unknown)"
if [ "${REUSED:-0}" = "1" ]; then
  ok "reused a validated pristine clone ($RESOLVED)"
else
  ok "cloned the package at $REF ($RESOLVED)"
fi

# Test hook: perturb the CLONE to prove this script fails for the right reason.
# Exercised by scripts/test-fixtures/consumer-install-negative.sh. It mutates
# only the scratch clone; the source tree is never touched.
if [ -n "${CONSUMER_INSTALL_FIXTURE:-}" ]; then
  echo "   fixture: $CONSUMER_INSTALL_FIXTURE (perturbing the clone)"
  case "$CONSUMER_INSTALL_FIXTURE" in
    undeclared-skill)
      mkdir -p "$CLONE/skills/rogue-undeclared-skill"
      printf -- '---\nname: rogue-undeclared-skill\ndescription: Not in the registry.\n---\n' \
        > "$CLONE/skills/rogue-undeclared-skill/SKILL.md" ;;
    missing-plugin-json)
      rm -f "$CLONE/plugin.json" ;;
    unresolvable-skill)
      rm -rf "$CLONE/skills/tauri-tray-app" ;;
    frontmatter-name-mismatch)
      perl -0pi -e 's/^name: tauri-tray-app$/name: not-the-directory-name/m' \
        "$CLONE/skills/tauri-tray-app/SKILL.md" ;;
    missing-harness-mirror)
      rm -rf "$CLONE/.claude/skills/realtime-skill-refiner" ;;
    *) echo "test-consumer-install: unknown fixture: $CONSUMER_INSTALL_FIXTURE" >&2; exit 2 ;;
  esac
fi

# --no-local forces a real object transfer rather than a hardlink farm, so the
# clone cannot accidentally share state with the source tree.

# ── Step 2: path isolation ───────────────────────────────────────────────────
# Assert the clone is genuinely independent before trusting anything it says.
if [ "$(cd "$CLONE" && pwd -P)" = "$(cd "$SOURCE_REPO" && pwd -P)" ]; then
  fail "the clone resolves to the source tree — the proof would be circular"
  exit 1
fi
case "$(cd "$CLONE" && pwd -P)/" in
  "$(cd "$SOURCE_REPO" && pwd -P)"/*) fail "the clone lives inside the source tree"; exit 1 ;;
esac
ok "clone is path-isolated from the source tree"

# ── Step 3: the 4-condition install contract, run FROM the clone ─────────────
# Deliberately invoke the clone's own copy of the verifier: a consumer has only
# what the package shipped. Running the source tree's copy would test the wrong
# artifact.
if [ ! -f "$CLONE/scripts/verify-skill-manifest.sh" ]; then
  fail "the package ships no scripts/verify-skill-manifest.sh — a consumer cannot validate it"
elif [ -n "${CONSUMER_INSTALL_SKIP_CONTRACT:-}" ] && [ -n "${CONSUMER_INSTALL_FIXTURE:-}" ]; then
  # The negative suite sets this for fixtures that target THIS script's own
  # assertions (registry resolution, harness mirrors). The contract verifier
  # spawns a python3 per skill and takes ~37s, which would make the suite
  # unusable; the fixtures that genuinely exercise the contract itself leave it
  # unset and pay the cost.
  echo "  – install contract: skipped (CONSUMER_INSTALL_SKIP_CONTRACT + fixture run)"
  CONTRACT_SKIPPED=1
else
  if bash "$CLONE/scripts/verify-skill-manifest.sh" "$CLONE" >"$WORK/contract.out" 2>&1; then
    ok "install contract: 4/4 conditions hold"
  else
    fail "install contract failed from the clone:"
    sed 's/^/      /' "$WORK/contract.out" >&2
  fi
fi

# ── Step 4: every required skill RESOLVES through the registry ───────────────
# Resolution, not file existence. A consumer's harness reads the registry
# (builder.manifest.json .skills[]) and follows it to skills/<name>/SKILL.md,
# then matches on the frontmatter `name`. A file that exists but is undeclared
# reaches nobody; a declared file whose frontmatter name disagrees resolves to
# the wrong skill.
MANIFEST="$CLONE/builder.manifest.json"
if [ ! -f "$MANIFEST" ]; then
  fail "the package ships no builder.manifest.json — nothing to resolve against"
else
  SKILL_ROOT="$(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get("distribution", {}).get("skillSourceRoot", "skills"))
' "$MANIFEST" 2>/dev/null || echo skills)"

  for skill in "${REQUIRED_SKILLS[@]}"; do
    if ! python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
names = [d.get("distribution", {}).get("packageSkill"), *d.get("skills", [])]
sys.exit(0 if sys.argv[2] in names else 1)
' "$MANIFEST" "$skill" 2>/dev/null; then
      fail "$skill: not in the registry — a consumer's harness never sees it"
      continue
    fi

    skill_md="$CLONE/$SKILL_ROOT/$skill/SKILL.md"
    if [ ! -f "$skill_md" ]; then
      fail "$skill: declared in the registry but resolves to no SKILL.md"
      continue
    fi

    fm_name="$(python3 -c '
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
if not m:
    sys.exit(1)
n = re.search(r"^name:\s*(.+)$", m.group(1), re.M)
if not n:
    sys.exit(1)
print(n.group(1).strip())
' "$skill_md" 2>/dev/null || true)"

    if [ -z "$fm_name" ]; then
      fail "$skill: resolves to a SKILL.md with no parseable frontmatter name"
    elif [ "$fm_name" != "$skill" ]; then
      fail "$skill: resolves to a SKILL.md whose frontmatter name is '$fm_name'"
    else
      ok "$skill resolves through the registry"
    fi
  done
fi

# ── Step 5: the harness mirrors a consumer actually reads ────────────────────
# Registry resolution proves the canonical skill is reachable. A consumer whose
# harness reads a mirror directory (Claude Code reads .claude/skills) needs the
# mirror too, or the skill is installed and still never fires.
# Every DECLARED skill, not only the required six. Checking the six alone would
# leave mirror drift in the rest of the package invisible here.
ALL_DECLARED=""
if [ -f "$MANIFEST" ]; then
  # .skills[] only. The package-level skill (distribution.packageSkill) is
  # deliberately NOT mirrored into the harness directories —
  # sync-harness-skills.sh:10 documents the exclusion — so including it here
  # would report intentional design as drift.
  ALL_DECLARED="$(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
print("\n".join(n for n in d.get("skills", []) if n))
' "$MANIFEST" 2>/dev/null || true)"
fi

for harness in .claude .agents; do
  missing=""
  for skill in "${REQUIRED_SKILLS[@]}"; do
    [ -f "$CLONE/$harness/skills/$skill/SKILL.md" ] || missing="$missing $skill"
  done
  if [ -n "$missing" ]; then
    fail "$harness/skills is missing:$missing"
    continue
  fi

  drifted=""
  declared_count=0
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    declared_count=$((declared_count + 1))
    [ -f "$CLONE/$harness/skills/$skill/SKILL.md" ] || drifted="$drifted $skill"
  done <<EOF_DECLARED
$ALL_DECLARED
EOF_DECLARED

  if [ -n "$drifted" ]; then
    fail "$harness/skills has mirror drift — declared but absent:$drifted"
  else
    ok "$harness/skills carries all $declared_count declared skills (incl. the ${#REQUIRED_SKILLS[@]} required)"
  fi
done

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "test-consumer-install: FAIL — $FAILURES problem(s); a consumer would not get a working package" >&2
  exit 1
fi
if [ "${CONTRACT_SKIPPED:-0}" = "1" ]; then
  echo "test-consumer-install: PASS (DEGRADED — install contract NOT verified) — ${#REQUIRED_SKILLS[@]} skills resolve"
  exit 0
fi
echo "test-consumer-install: PASS — a consumer following the documented contract receives all ${#REQUIRED_SKILLS[@]} skills"
