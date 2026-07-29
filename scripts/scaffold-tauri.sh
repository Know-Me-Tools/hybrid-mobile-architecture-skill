#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib-knowme-builder.sh"

OUT="${1:-}"
if [[ -z "$OUT" ]]; then
  printf 'usage: %s <path> [legacy app name]\n' "$0" >&2
  exit 2
fi
builder_deprecation_notice "scaffold-tauri.sh" "new <path> --profile tauri-desktop --mode runnable"
run_knowme_builder new "$OUT" --profile tauri-desktop --mode runnable
