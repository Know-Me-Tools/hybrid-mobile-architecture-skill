#!/usr/bin/env bash
# scripts/sync-harness-skills.sh
# Project the canonical public companion skills into scaffold and harness trees.
#
# Usage:
#   bash scripts/sync-harness-skills.sh          # sync
#   bash scripts/sync-harness-skills.sh --check  # verify only, non-zero on drift (CI)
#
# skills/ is the SOURCE. templates/project-skills and the six harness directories
# are generated copies. The package-level hybrid-mobile-architecture skill is
# intentionally not scaffolded into consuming projects.
#
# The pack's own .claude/skills also carries vendored openspec-* skills that have
# no template. Those are left untouched: this script only mirrors what the
# templates directory owns.

set -euo pipefail

MODE="${1:-sync}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$PACK_ROOT/skills"
PROJECT_TARGET="$PACK_ROOT/templates/project-skills"
MANIFEST="$PACK_ROOT/builder.manifest.json"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

[[ -d "$SRC" ]] || { echo "FATAL: $SRC not found" >&2; exit 1; }
[[ -f "$MANIFEST" ]] || { echo "FATAL: $MANIFEST not found" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq is required" >&2; exit 1; }

HARNESS_DIRS=(.claude .codex .opencode .kimi .agents .kimi-code)

SKILLS=()
while IFS= read -r skill; do
  SKILLS+=("$skill")
done < <(jq -r '.skills[]' "$MANIFEST")

[[ ${#SKILLS[@]} -gt 0 ]] || { echo "FATAL: no skills found under $SRC" >&2; exit 1; }

DRIFT=0
TARGET_ROOTS=("$PROJECT_TARGET")
for harness in "${HARNESS_DIRS[@]}"; do
  TARGET_ROOTS+=("$PACK_ROOT/$harness/skills")
done

for target_root in "${TARGET_ROOTS[@]}"; do
  if [[ ! -d "$target_root" ]]; then
    if [[ "$MODE" == "--check" ]]; then
      relative_target="${target_root#"$PACK_ROOT/"}"
      echo -e "  ${RED}✗${NC} missing generated root: $relative_target"
      DRIFT=1
      continue
    fi
    mkdir -p "$target_root"
  fi
  for skill in "${SKILLS[@]}"; do
    src="$SRC/$skill"
    dst="$target_root/$skill"
    if [[ "$MODE" == "--check" ]]; then
      if ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
        relative_target="${dst#"$PACK_ROOT/"}"
        echo -e "  ${RED}✗${NC} drift: $relative_target"
        DRIFT=1
      fi
    else
      # Replace wholesale: a merge would leave files deleted from the source
      # behind in the copy, which is drift wearing a different hat.
      rm -rf "$dst"
      mkdir -p "$dst"
      cp -R "$src/." "$dst/"
    fi
  done
done

if [[ "$MODE" == "--check" ]]; then
  if [[ $DRIFT -eq 0 ]]; then
    echo -e "${GREEN}  ✓ scaffold and all ${#HARNESS_DIRS[@]} harness trees match skills/${NC}"
  else
    echo -e "${RED}  ✗ generated skill trees have drifted — run: bash scripts/sync-harness-skills.sh${NC}"
    exit 1
  fi
else
  echo -e "${CYAN}Synced ${#SKILLS[@]} companion skills into scaffold and ${#HARNESS_DIRS[@]} harness trees${NC}"
  echo -e "${GREEN}  ✓ skills is the source of truth${NC}"
fi
