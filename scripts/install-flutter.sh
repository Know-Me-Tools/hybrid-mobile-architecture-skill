#!/usr/bin/env bash
# scripts/install-flutter.sh
# Install Flutter SDK 3.29+ (latest stable) via git clone or FVM.
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
  info "Installing Flutter stable via FVM..."
  fvm install stable
  fvm global stable
  ok "Flutter $(fvm flutter --version | head -1) via FVM"
  echo ""
  echo "  Add to PATH: export PATH=\"\$HOME/.pub-cache/bin:\$PATH\""
  echo "  Use in project: fvm flutter <command>"
  exit 0
fi

# ── Direct install via git ─────────────────────────────────────────────────
FLUTTER_DIR="${HOME}/development/flutter"

if [[ -d "$FLUTTER_DIR" ]]; then
  info "Flutter already at $FLUTTER_DIR — updating..."
  cd "$FLUTTER_DIR"
  git fetch origin
  git checkout stable
  git pull
else
  info "Cloning Flutter SDK to $FLUTTER_DIR..."
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR" --depth 1
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
