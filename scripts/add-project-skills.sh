#!/usr/bin/env bash
# scripts/add-project-skills.sh
# Emit the TJ-ARCH-MOB-001 project-local UI/UX skills + activation hooks into a project.
# Usage: bash scripts/add-project-skills.sh [project-root]
# Example: bash scripts/add-project-skills.sh ./my-hybrid-app
#
# Additive and backward-compatible: copies project skill templates into every
# supported harness, installs two Claude hooks, and merges the hook settings into
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
HARNESS_DIRS=(.claude .codex .opencode .kimi .agents .kimi-code)
step "Installing project-local skills into all supported harnesses"
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/hooks"

# ── Skills ──────────────────────────────────────────────────────────────────
for harness in "${HARNESS_DIRS[@]}"; do
  mkdir -p "$ROOT/$harness/skills"
  for skill in reference-ui-fidelity content-block-ui hybrid-design-tokens tauri-ui-review tauri-custom-titlebar mobile-navigation flutter-golden-ui a11y-gate hybrid-runtime-verification deploy-hybrid-agentic-stack karpathy-progress-memory build-branded-docusaurus orchestrate-prometheus-application; do
    if [[ -d "$SRC/$skill" ]]; then
      mkdir -p "$ROOT/$harness/skills/$skill"
      cp -R "$SRC/$skill/." "$ROOT/$harness/skills/$skill/"
    fi
  done
  ok "skills: $harness"
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
        | .UserPromptSubmit = ((($h.UserPromptSubmit // []) + $add.hooks.UserPromptSubmit) | unique_by(tostring))
        | .PostToolUse      = ((($h.PostToolUse // [])      + $add.hooks.PostToolUse)      | unique_by(tostring)))
  ' "$SETTINGS" "$HOOKS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS"
  ok "merged activation hooks into existing .claude/settings.json (jq)"
else
  cp "$HOOKS_JSON" "$CLAUDE_DIR/settings.hooks.json"
  warn "jq not found — wrote hooks to .claude/settings.hooks.json; merge into settings.json by hand"
fi

echo ""
echo -e "${GREEN}  ✅ Project-local skills installed${NC}"
echo "     13 skills × 6 harnesses · 2 activation hooks · fidelity, runtime, deployment, documentation, orchestration, memory, and WCAG 2.2 AA gates"
echo "     See references/ui-skills.md for the external skill stack."
