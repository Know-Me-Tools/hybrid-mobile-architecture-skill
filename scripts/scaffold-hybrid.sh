#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib-knowme-builder.sh"

PROJECT="${1:-}"
if [[ -z "$PROJECT" ]]; then
  printf 'usage: %s <path> [legacy options]\n' "$0" >&2
  exit 2
fi
shift
if (( $# > 0 )); then
  printf 'warning: legacy scaffold options are ignored; profile state now owns runtime selection\n' >&2
fi
builder_deprecation_notice "scaffold-hybrid.sh" "new <path> --profile sovereign-hybrid --mode runnable"
run_knowme_builder new "$PROJECT" --profile sovereign-hybrid --mode runnable
