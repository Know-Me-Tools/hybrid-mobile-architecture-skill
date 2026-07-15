#!/usr/bin/env bash
# scripts/install-flutter.sh
# Install Flutter SDK on the BETA channel (this project's required channel — it ships
# the Dart MCP server and the current SurrealDB/Riverpod/frb-compatible Dart SDK).
# Usage: bash scripts/install-flutter.sh [--fvm]

set -euo pipefail

USE_FVM=false
[[ "${1:-}" == "--fvm" ]] && USE_FVM=true

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
info() { echo -e "${CYAN}  →${NC} $1"; }

# ── FVM (Flutter Version Manager — recommended for teams) ─────────────────
if $USE_FVM; then
  info "Installing FVM (Flutter Version Manager)..."
  if ! command -v fvm &>/dev/null; then
    dart pub global activate fvm
  fi
  ok "FVM installed: $(fvm --version)"
  info "Installing Flutter beta via FVM..."
  fvm install beta
  fvm global beta
  ok "Flutter $(fvm flutter --version | head -1) via FVM"
  echo ""
  echo "  Add to PATH: export PATH=\"\$HOME/.pub-cache/bin:\$PATH\""
  echo "  Use in project: fvm flutter <command>"
  exit 0
fi

# ── Direct install via git ─────────────────────────────────────────────────
# IMPORTANT: clone -b beta, NON-shallow. A shallow (--depth 1) clone cannot switch
# channels later ('flutter channel <x>' needs full history) — this bit us once.
FLUTTER_DIR="${HOME}/development/flutter"

if [[ -d "$FLUTTER_DIR" ]]; then
  info "Flutter already at $FLUTTER_DIR — switching to beta and upgrading..."
  cd "$FLUTTER_DIR"
  # Unshallow first if this checkout was ever cloned with --depth 1.
  if [[ -f .git/shallow ]]; then
    info "Repo is shallow — unshallowing so channel switches work..."
    git fetch --unshallow origin
  fi
  git fetch origin
  flutter channel beta
  flutter upgrade
else
  info "Cloning Flutter SDK (beta channel, full history) to $FLUTTER_DIR..."
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  git clone https://github.com/flutter/flutter.git -b beta "$FLUTTER_DIR"
fi

# Add to PATH for current session
export PATH="$FLUTTER_DIR/bin:$PATH"

info "Running flutter doctor..."
flutter doctor --no-color

ok "Flutter $(flutter --version | head -1)"
echo ""
echo "  Permanently add to PATH:"
echo "  export PATH=\"\$HOME/development/flutter/bin:\$PATH\""
echo ""
echo "  Then install required tools:"
echo "  flutter doctor --android-licenses"
