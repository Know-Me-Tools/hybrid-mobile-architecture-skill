#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib-knowme-builder.sh"

ROOT="${1:-.}"
builder_deprecation_notice "scaffold-packages.sh" "add module shared-packages --path <project>"
printf 'warning: package surfaces are now generated from typed manifests; legacy heredoc output is retired\n' >&2
run_knowme_builder add module shared-packages --path "$ROOT"
