#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib-knowme-builder.sh"

FEATURE="${1:-}"
PLATFORM="${2:-}"
ROOT="${3:-.}"
if [[ -z "$FEATURE" ]]; then
  printf 'usage: %s <feature-name> [legacy platform] [project-root]\n' "$0" >&2
  exit 2
fi
if [[ -n "$PLATFORM" ]]; then
  printf 'warning: platform is derived from the adopted Builder profile, not `%s`\n' "$PLATFORM" >&2
fi
builder_deprecation_notice "new-feature.sh" "add feature <name> --path <project>"
run_knowme_builder add feature "$FEATURE" --path "$ROOT"
