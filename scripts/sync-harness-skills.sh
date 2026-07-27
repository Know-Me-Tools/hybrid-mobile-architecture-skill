#!/usr/bin/env bash
# scripts/sync-harness-skills.sh
# Mirror templates/project-skills into every harness skill tree in THIS repo.
#
# Usage:
#   bash scripts/sync-harness-skills.sh          # sync
#   bash scripts/sync-harness-skills.sh --check  # verify only, non-zero on drift (CI)
#
# templates/project-skills/ is the SOURCE. The six harness directories are
# copies, and a copy that is edited directly is a copy that silently diverges —
# each harness would then teach a different rule for the same situation. Editing
# the source and running this script is the only supported flow.
#
# The pack's own .claude/skills also carries vendored openspec-* skills that have
# no template. Those are left untouched: this script only mirrors what the
# templates directory owns.

set -euo pipefail

MODE="${1:-sync}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$PACK_ROOT/templates/project-skills"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

[[ -d "$SRC" ]] || { echo "FATAL: $SRC not found" >&2; exit 1; }

HARNESS_DIRS=(.claude .codex .opencode .kimi .agents .kimi-code)

SKILLS=()
while IFS= read -r skill_md; do
  SKILLS+=("$(basename "$(dirname "$skill_md")")")
done < <(find "$SRC" -maxdepth 2 -name 'SKILL.md' -print | sort)

[[ ${#SKILLS[@]} -gt 0 ]] || { echo "FATAL: no skills found under $SRC" >&2; exit 1; }

DRIFT=0
for harness in "${HARNESS_DIRS[@]}"; do
  target_root="$PACK_ROOT/$harness/skills"
  [[ -d "$target_root" ]] || continue
  for skill in "${SKILLS[@]}"; do
    src="$SRC/$skill"
    dst="$target_root/$skill"
    if [[ "$MODE" == "--check" ]]; then
      if ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
        echo -e "  ${RED}✗${NC} drift: $harness/skills/$skill"
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
    echo -e "${GREEN}  ✓ all ${#HARNESS_DIRS[@]} harness trees match templates/project-skills${NC}"
  else
    echo -e "${RED}  ✗ harness skill trees have drifted — run: bash scripts/sync-harness-skills.sh${NC}"
    exit 1
  fi
else
  echo -e "${CYAN}Synced ${#SKILLS[@]} skills into ${#HARNESS_DIRS[@]} harness trees${NC}"
  echo -e "${GREEN}  ✓ templates/project-skills is the source of truth${NC}"
fi
