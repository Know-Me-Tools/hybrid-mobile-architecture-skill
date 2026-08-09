#!/usr/bin/env bash
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$script_dir/install-harness-package.sh" "$@"
