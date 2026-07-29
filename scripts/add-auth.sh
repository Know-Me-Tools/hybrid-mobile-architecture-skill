#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib-knowme-builder.sh"

PROVIDER="${1:-verified-session}"
PLATFORM="${2:-}"
ROOT="${3:-.}"
if [[ -n "$PLATFORM" ]]; then
  printf 'warning: platform is derived from the adopted Builder profile, not `%s`\n' "$PLATFORM" >&2
fi
builder_deprecation_notice "add-auth.sh" "add auth <name> --path <project>"
run_knowme_builder add auth "$PROVIDER" --path "$ROOT"
