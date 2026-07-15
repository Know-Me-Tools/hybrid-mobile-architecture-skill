#!/usr/bin/env bash
# KBD multi-harness dispatch driver for scaffold-full-hybrid-project.
# Usage: dispatch.sh <change-id> <harness> <model> [base-ref]
#   harness ∈ codex | opencode | claude | kimi
# Creates an isolated worktree, seeds the prompt, invokes the harness non-interactively.
set -euo pipefail

REPO="/Users/gqadonis/Projects/hybrid-mobile-architecture-src"
DISPATCH="$REPO/.kbd-orchestrator/dispatch"
CHANGE="${1:?change-id required}"
HARNESS="${2:?harness required}"
MODEL="${3:?model required}"
BASE="${4:-main}"

WT="$DISPATCH/worktrees/$CHANGE"
BRANCH="exec/$CHANGE"
LOG="$DISPATCH/logs/$CHANGE.log"
PROMPT_FILE="$DISPATCH/prompts/$CHANGE.md"

# Compose the per-change prompt: shared preamble + change pointer.
{
  cat "$DISPATCH/prompts/_preamble.md"
  echo ""
  echo "## YOUR CHANGE: $CHANGE"
  echo ""
  echo "Read openspec/changes/$CHANGE/proposal.md and the matching entry in plan.md."
  echo "Implement it fully per the philosophy above. Assigned model: $MODEL ($HARNESS)."
} > "$PROMPT_FILE"

# Create worktree if absent.
if [ ! -d "$WT" ]; then
  git -C "$REPO" worktree add -b "$BRANCH" "$WT" "$BASE" >/dev/null 2>&1 \
    || git -C "$REPO" worktree add "$WT" "$BRANCH" >/dev/null 2>&1
fi

echo "[dispatch] $CHANGE → $HARNESS/$MODEL  worktree=$WT" | tee -a "$LOG"
PROMPT="$(cat "$PROMPT_FILE")"

case "$HARNESS" in
  codex)
    # Use brew codex 0.144.4 explicitly (cargo 0.0.0 shadows it on PATH); gpt-5.6-sol needs >=0.144.
    "${CODEX_BIN:-/opt/homebrew/bin/codex}" exec -C "$WT" -m "$MODEL" \
      --dangerously-bypass-approvals-and-sandbox "$PROMPT" >>"$LOG" 2>&1 ;;
  opencode|kimi)
    opencode run --dir "$WT" -m "$MODEL" "$PROMPT" >>"$LOG" 2>&1 ;;
  claude)
    (cd "$WT" && claude -p "$PROMPT" --dangerously-skip-permissions >>"$LOG" 2>&1) ;;
  *) echo "unknown harness: $HARNESS" >&2; exit 2 ;;
esac

echo "[dispatch] $CHANGE done (exit $?)" | tee -a "$LOG"
