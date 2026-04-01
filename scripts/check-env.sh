#!/usr/bin/env bash
# scripts/check-env.sh
# Check and optionally install all required tools for hybrid mobile development.
# Usage: bash scripts/check-env.sh [--install]

set -euo pipefail

INSTALL_MODE=false
[[ "${1:-}" == "--install" ]] && INSTALL_MODE=true

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
fail() { echo -e "${RED}  ✗${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1"; }
info() { echo -e "${CYAN}  →${NC} $1"; }

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Hybrid Mobile Architecture — Environment Check  ${NC}"
echo -e "${CYAN}  TJ-ARCH-MOB-001 · Prometheus AGS                ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo ""

MISSING=()

# ── Rust ─────────────────────────────────────────────────────────────────
echo "Rust toolchain"
if command -v rustc &>/dev/null; then
  RUST_VER=$(rustc --version | awk '{print $2}')
  RUST_MAJOR=$(echo "$RUST_VER" | cut -d. -f1)
  RUST_MINOR=$(echo "$RUST_VER" | cut -d. -f2)
  if [[ $RUST_MAJOR -gt 1 ]] || [[ $RUST_MAJOR -eq 1 && $RUST_MINOR -ge 80 ]]; then
    ok "rustc $RUST_VER"
  else
    warn "rustc $RUST_VER — requires 1.80+. Run: rustup update stable"
    MISSING+=("rust-update")
  fi
else
  fail "Rust not found"
  MISSING+=("rust")
  if $INSTALL_MODE; then
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source "$HOME/.cargo/env"
    ok "Rust installed"
  fi
fi

# Rust targets
TARGETS=$(rustup target list --installed 2>/dev/null || true)
for target in aarch64-linux-android armv7-linux-androideabi x86_64-linux-android \
              aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios; do
  if echo "$TARGETS" | grep -q "$target"; then
    ok "  target: $target"
  else
    warn "  target $target not installed"
    if $INSTALL_MODE; then
      info "  Installing $target..."
      rustup target add "$target" && ok "  $target installed"
    fi
  fi
done

echo ""

# ── Cargo tools ───────────────────────────────────────────────────────────
echo "Cargo tools"

check_cargo_tool() {
  local bin="$1"; local pkg="$2"; local ver_flag="${3:---version}"
  if command -v "$bin" &>/dev/null; then
    ok "$bin ($(${bin} ${ver_flag} 2>&1 | head -1))"
  else
    fail "$bin not found"
    MISSING+=("$pkg")
    if $INSTALL_MODE; then
      info "Installing $pkg..."
      cargo install "$pkg" && ok "$bin installed"
    fi
  fi
}

check_cargo_tool "flutter_rust_bridge_codegen" "flutter_rust_bridge_codegen"
check_cargo_tool "cargo-ndk"                   "cargo-ndk"
# Tauri CLI: check via cargo tauri
if cargo tauri --version &>/dev/null 2>&1; then
  ok "cargo-tauri ($(cargo tauri --version 2>&1))"
else
  fail "tauri-cli not found"
  MISSING+=("tauri-cli")
  if $INSTALL_MODE; then
    info "Installing tauri-cli ^2..."
    cargo install tauri-cli --version "^2" && ok "tauri-cli installed"
  fi
fi

echo ""

# ── Flutter ────────────────────────────────────────────────────────────────
echo "Flutter SDK"
if command -v flutter &>/dev/null; then
  FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
  ok "flutter $FLUTTER_VER"
  # Check Dart
  DART_VER=$(dart --version 2>/dev/null | awk '{print $4}')
  ok "dart $DART_VER"
else
  fail "Flutter not found"
  MISSING+=("flutter")
  if $INSTALL_MODE; then
    bash "$(dirname "$0")/install-flutter.sh"
  fi
fi

echo ""

# ── Node.js ────────────────────────────────────────────────────────────────
echo "Node.js"
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
  if [[ $NODE_MAJOR -ge 22 ]]; then
    ok "node $NODE_VER"
    ok "npm $(npm --version)"
  else
    warn "node $NODE_VER — requires 22+ LTS"
    MISSING+=("node-update")
    if $INSTALL_MODE; then
      info "Installing fnm and Node 22 LTS..."
      curl -fsSL https://fnm.vercel.app/install | bash
      export PATH="$HOME/.fnm:$PATH"
      eval "$(fnm env)"
      fnm install --lts && fnm use --lts
      ok "Node LTS installed"
    fi
  fi
else
  fail "Node.js not found"
  MISSING+=("node")
  if $INSTALL_MODE; then
    info "Installing fnm and Node 22 LTS..."
    curl -fsSL https://fnm.vercel.app/install | bash
    export PATH="$HOME/.fnm:$PATH"
    eval "$(fnm env)"
    fnm install --lts && fnm use --lts
    ok "Node LTS installed"
  fi
fi

# pnpm (preferred for Tauri projects)
if command -v pnpm &>/dev/null; then
  ok "pnpm $(pnpm --version)"
else
  warn "pnpm not found (recommended)"
  if $INSTALL_MODE; then
    npm install -g pnpm && ok "pnpm installed"
  fi
fi

echo ""

# ── Android SDK (optional) ─────────────────────────────────────────────────
echo "Android SDK (optional for Android builds)"
if [[ -n "${ANDROID_HOME:-}" ]] || [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  ok "ANDROID_HOME set: ${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
else
  warn "ANDROID_HOME not set — needed for Android builds"
fi
if [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
  ok "ANDROID_NDK_HOME set: $ANDROID_NDK_HOME"
else
  warn "ANDROID_NDK_HOME not set — needed for cargo-ndk"
fi

echo ""

# ── Xcode (macOS only) ─────────────────────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]]; then
  echo "Xcode (macOS — required for iOS builds)"
  if xcode-select -p &>/dev/null; then
    ok "Xcode CLI tools: $(xcode-select -p)"
  else
    fail "Xcode CLI tools not found"
    MISSING+=("xcode")
    if $INSTALL_MODE; then
      xcode-select --install
    fi
  fi
  echo ""
fi

# ── Summary ───────────────────────────────────────────────────────────────
if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo -e "${GREEN}✅ All required tools are present. Ready to build.${NC}"
else
  echo -e "${YELLOW}⚠  Missing tools: ${MISSING[*]}${NC}"
  echo ""
  echo "  Run with --install to install missing tools:"
  echo "  bash scripts/check-env.sh --install"
fi
echo ""
