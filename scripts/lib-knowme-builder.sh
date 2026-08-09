#!/usr/bin/env bash
set -euo pipefail

KNOWME_BUILDER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KNOWME_BUILDER_REPO_ROOT="$(cd "$KNOWME_BUILDER_SCRIPT_DIR/.." && pwd)"

run_knowme_builder() {
  if [[ "${KNOWME_BUILDER_FORCE_SOURCE:-0}" != "1" ]] && command -v knowme-builder >/dev/null 2>&1; then
    command knowme-builder "$@"
    return
  fi
  command cargo run \
    --quiet \
    --manifest-path "$KNOWME_BUILDER_REPO_ROOT/tools/knowme-builder/Cargo.toml" \
    -- "$@"
}

builder_deprecation_notice() {
  printf 'warning: %s is deprecated; use `knowme-builder %s` directly\n' "$1" "$2" >&2
}
