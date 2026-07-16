#!/usr/bin/env bash
# scripts/add-project-skills.sh
# Emit the TJ-ARCH-MOB-001 project-local UI/UX skills + activation hooks into a project.
# Usage: bash scripts/add-project-skills.sh [project-root]
# Example: bash scripts/add-project-skills.sh ./my-hybrid-app
#
# Additive and backward-compatible: copies 5 skill templates into <root>/.claude/skills/,
# two hook scripts into <root>/.claude/hooks/, and merges the hook settings into
# <root>/.claude/settings.json (deep-merge via jq when available; safe fallback otherwise).

set -euo pipefail

ROOT="${1:-.}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$SKILL_DIR/templates/project-skills"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1"; }

if [[ ! -d "$SRC" ]]; then
  echo "Project-skill templates not found at $SRC" >&2
  exit 1
fi

CLAUDE_DIR="$ROOT/.claude"
step "Installing project-local UI/UX skills into $CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/hooks"

# ── Skills ──────────────────────────────────────────────────────────────────
for skill in content-block-ui hybrid-design-tokens tauri-ui-review tauri-custom-titlebar flutter-golden-ui a11y-gate; do
  if [[ -d "$SRC/$skill" ]]; then
    mkdir -p "$CLAUDE_DIR/skills/$skill"
    cp "$SRC/$skill/SKILL.md" "$CLAUDE_DIR/skills/$skill/SKILL.md"
    ok "skill: $skill"
  fi
done

# ── Hooks ───────────────────────────────────────────────────────────────────
cp "$SRC/hooks/skill-activation.py" "$CLAUDE_DIR/hooks/skill-activation.py"
cp "$SRC/hooks/a11y-reminder.py"    "$CLAUDE_DIR/hooks/a11y-reminder.py"
chmod +x "$CLAUDE_DIR/hooks/skill-activation.py" "$CLAUDE_DIR/hooks/a11y-reminder.py"
ok "hooks: skill-activation.py, a11y-reminder.py"

# ── Settings merge ──────────────────────────────────────────────────────────
SETTINGS="$CLAUDE_DIR/settings.json"
HOOKS_JSON="$SRC/settings.hooks.json"

if [[ ! -f "$SETTINGS" ]]; then
  cp "$HOOKS_JSON" "$SETTINGS"
  ok "created .claude/settings.json with activation hooks"
elif command -v jq >/dev/null 2>&1; then
  # Deep-merge: append our hook arrays into any existing hooks config.
  tmp="$(mktemp)"
  jq -s '
    .[0] as $cur | .[1] as $add
    | $cur
    | .hooks = ((.hooks // {}) as $h
        | $h
        | .UserPromptSubmit = (($h.UserPromptSubmit // []) + $add.hooks.UserPromptSubmit)
        | .PostToolUse      = (($h.PostToolUse // [])      + $add.hooks.PostToolUse))
  ' "$SETTINGS" "$HOOKS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS"
  ok "merged activation hooks into existing .claude/settings.json (jq)"
else
  cp "$HOOKS_JSON" "$CLAUDE_DIR/settings.hooks.json"
  warn "jq not found — wrote hooks to .claude/settings.hooks.json; merge into settings.json by hand"
fi

echo ""
echo -e "${GREEN}  ✅ Project-local UI/UX skills installed${NC}"
echo "     5 skills · 2 activation hooks · WCAG 2.2 AA gate"
echo "     See references/ui-skills.md for the external skill stack."
