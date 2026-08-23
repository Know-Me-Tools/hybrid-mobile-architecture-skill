#!/usr/bin/env bash
# scripts/verify-scaffold.sh
# Scaffold a throwaway project and prove it matches what this pack promises.
#
# Usage:
#   bash scripts/verify-scaffold.sh            # verify against ci/expected-tree.txt
#   bash scripts/verify-scaffold.sh --update   # regenerate the manifest after an
#                                              # INTENTIONAL scaffold change
#
# Why this exists instead of a committed example app:
#
# This pack used to carry a ~40k LOC snapshot of a real product under apps/,
# committed as "the example". It read like generator output but was not, so when
# the generator fell behind the product, nothing failed. That is precisely how the
# drift this file guards against went unnoticed for months.
#
# A generated fixture cannot go stale. If the scaffold changes, this check fails
# on the next push, and the only way to make it pass is to look at the diff and
# decide whether the change was intended.
#
# The manifest records STRUCTURE (paths + key manifest values), not file contents.
# Contents belong to the templates; pinning them here would make every comment
# edit a CI failure and train everyone to run --update without reading.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$PACK_ROOT/ci/expected-tree.txt"
MODE="${1:-verify}"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
die()  { echo -e "${RED}  ✗${NC} $1" >&2; exit 1; }

# Fixed identity so the manifest is deterministic. Deliberately NOT the pack's
# own defaults: a placeholder that only ever substitutes to its default value is
# a placeholder nobody has tested.
APP_NAME="verify-app"
APP_ORG="com.example"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

step "Scaffolding $APP_NAME into a throwaway directory"
mkdir -p "$WORK/proj"
KNOWME_BUILDER_FORCE_SOURCE="${KNOWME_BUILDER_FORCE_SOURCE:-1}" \
  bash "$SCRIPT_DIR/scaffold-rust-core.sh" "$WORK/proj" embedded "$APP_NAME" "$APP_ORG" >/dev/null
bash "$SCRIPT_DIR/add-project-skills.sh" "$WORK/proj" >/dev/null
ok "scaffolded"

# ── Build the structural manifest ───────────────────────────────────────────
# Sorted, path-only, plus a few load-bearing manifest values. Everything that
# varies per run (timestamps, absolute paths, lockfile hashes) is excluded, or
# the manifest would never match twice.
build_manifest() {
  local root="$1"
  {
    echo "# Structural manifest of the scaffold output."
    echo "# Regenerate: bash scripts/verify-scaffold.sh --update"
    echo "# Paths and key manifest values only — never file contents."
    echo
    echo "## paths"
    ( cd "$root" && find . -type f \
        -not -path './rust/vendor/*' \
        -not -path './rust/target/*' \
        -not -name '*.lock' \
        | sed 's|^\./||' | LC_ALL=C sort )
    echo
    echo "## builder metadata"
    grep -E '^(profile|builderVersion|requiredPrometheusContract|generationMode) =' \
      "$root/.knowme-builder/project.toml" | sort
  } 2>/dev/null
}

ACTUAL="$WORK/actual-tree.txt"
build_manifest "$WORK/proj" > "$ACTUAL"

if [[ "$MODE" == "--update" ]]; then
  mkdir -p "$(dirname "$MANIFEST")"
  cp "$ACTUAL" "$MANIFEST"
  ok "manifest updated: ci/expected-tree.txt ($(grep -c . "$MANIFEST") lines)"
  echo
  echo "  Review the diff before committing. This file is the only thing that"
  echo "  notices when the scaffold changes shape."
  exit 0
fi

# ── Verify ──────────────────────────────────────────────────────────────────
step "Comparing against ci/expected-tree.txt"
[[ -f "$MANIFEST" ]] || die "manifest missing — run: bash scripts/verify-scaffold.sh --update"

if diff -u "$MANIFEST" "$ACTUAL" > "$WORK/tree.diff"; then
  ok "scaffold output matches the expected structure"
else
  echo -e "${RED}  ✗ scaffold output changed:${NC}" >&2
  sed -n '1,60p' "$WORK/tree.diff" >&2
  echo >&2
  echo "  If this change was INTENTIONAL:" >&2
  echo "    bash scripts/verify-scaffold.sh --update   # then commit the manifest" >&2
  echo "  If not, the scaffold regressed — fix it rather than updating the manifest." >&2
  exit 1
fi

# ── Placeholder hygiene ─────────────────────────────────────────────────────
# A surviving __APP_ID__ in a JNI lookup compiles fine and fails at class
# resolution on device, which is the most expensive place to find it.
# Scoped to EMITTED CODE. The skill trees are excluded because skills legitimately
# document placeholders that are not ours to substitute — Docusaurus's
# __SITE_NAME__, Tauri's __TAURI_INTERNALS__ global. Grepping them as leaks would
# make this check cry wolf, and a check that cries wolf gets disabled.
step "Checking placeholder substitution"
LEFTOVER="$(grep -rlE '__APP_[A-Z_]+__|__ENV_PREFIX__|@[A-Z_]+_VERSION@|@EMBEDDING_DIM@' \
  "$WORK/proj/rust" "$WORK/proj/scripts" 2>/dev/null || true)"
if [[ -n "$LEFTOVER" ]]; then
  echo "$LEFTOVER" >&2
  die "unsubstituted placeholders in emitted code"
fi
ok "no unsubstituted placeholders in emitted code"

# ── Skill projection actually happened ──────────────────────────────────────
step "Checking companion skill projection"
# Derive the expected count from templates/project-skills, the source the
# projection is generated FROM. A hardcoded literal rots the moment a companion
# skill is added: this read "29" while six v0.2.0 skills had since shipped, and
# nothing noticed because the gate itself was red for an unrelated reason.
expected_companions="$(find "$PACK_ROOT/templates/project-skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
[[ "$expected_companions" -gt 0 ]] \
  || die "derived 0 companion skills from templates/project-skills — refusing a vacuous assertion"

for harness in .claude .codex .opencode .kimi .agents .kimi-code; do
  skill_count="$(find "$WORK/proj/$harness/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
  [[ "$skill_count" == "$expected_companions" ]] \
    || die "$harness contains $skill_count skills; expected $expected_companions companions (from templates/project-skills)"
  [[ ! -e "$WORK/proj/$harness/skills/hybrid-mobile-architecture" ]] || \
    die "$harness incorrectly contains the repository package-routing skill"
done
ok "$expected_companions companion skills projected to all six project harnesses"

# ── Manifests parse ─────────────────────────────────────────────────────────
step "Validating emitted manifests"
python3 - "$WORK/proj/rust" <<'PYEOF'
import pathlib, sys, tomllib
root = pathlib.Path(sys.argv[1])
count = 0
for f in root.rglob('*.toml'):
    if 'vendor' in f.parts or 'target' in f.parts:
        continue
    count += 1
    try:
        tomllib.load(open(f, 'rb'))
    except Exception as exc:
        print(f"  ✗ {f.relative_to(root)}: {exc}", file=sys.stderr)
        sys.exit(1)
print(f"  ✓ {count} TOML manifests parse")
PYEOF

echo
echo -e "${GREEN}  ✓ scaffold verification passed${NC}"
echo
