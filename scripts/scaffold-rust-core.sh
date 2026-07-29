#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib-knowme-builder.sh"

OUT="${1:-}"
if [[ -z "$OUT" ]]; then
  printf 'usage: %s <path>\n' "$0" >&2
  exit 2
fi
builder_deprecation_notice "scaffold-rust-core.sh" "new <path> --profile sovereign-hybrid --mode runnable"
printf 'warning: Builder 2.0 generates the Rust core with its governed application surfaces\n' >&2
run_knowme_builder new "$OUT" --profile sovereign-hybrid --mode runnable
