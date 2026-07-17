#!/usr/bin/env bash
# scripts/check-env.sh
# Four-pillar bootstrap: verify-or-install everything TJ-ARCH-MOB-001 needs on this box.
# Usage: bash scripts/check-env.sh [--install] [--full]
#   (default)  check-only, no remediation
#   --install  remediate normal-cost items (versions, missing tools)
#   --full     also run long operations (Flutter beta upgrade, full Prometheus
#              Skill System install) — multi-GB / minutes, not for CI
#
# Pillars:
#   1. Rust toolchain + wasm32 target + Prometheus Skill System (full instance)
#   2. OpenSpec (latest, scoped npm name)
#   3. Flutter/Dart BETA channel (ships the Dart MCP server)
#   4. Node 24 LTS + bun + pnpm + TypeScript (latest)

set -euo pipefail

INSTALL_MODE=false
FULL_MODE=false
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL_MODE=true ;;
    --full)    INSTALL_MODE=true; FULL_MODE=true ;;
  esac
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
fail() { echo -e "${RED}  ✗${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1"; }
info() { echo -e "${CYAN}  →${NC} $1"; }
pillar() { echo ""; echo -e "${CYAN}── Pillar $1: $2 ${NC}"; }

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Hybrid Mobile Architecture — Environment Check  ${NC}"
echo -e "${CYAN}  TJ-ARCH-MOB-001 · Prometheus AGS                ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
$INSTALL_MODE && echo -e "${YELLOW}  mode: --install$($FULL_MODE && echo " --full")${NC}" || echo -e "${CYAN}  mode: check-only (pass --install to remediate)${NC}"

MISSING=()
version_ge() { # version_ge <have> <want> — dotted numeric compare, "have >= want"
  [[ "$1" == "$2" ]] && return 0
  local IFS=.; local -a a=($1) b=($2)
  for ((i=0; i<${#b[@]}; i++)); do
    local ai="${a[i]:-0}" bi="${b[i]:-0}"
    ((10#$ai > 10#$bi)) && return 0
    ((10#$ai < 10#$bi)) && return 1
  done
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# Pillar 1 — Rust toolchain + wasm32 + Prometheus Skill System
# ═══════════════════════════════════════════════════════════════════════════
pillar 1 "Rust toolchain + WASM + Prometheus Skill System"

if command -v rustc &>/dev/null; then
  RUST_VER=$(rustc --version | awk '{print $2}' | cut -d- -f1)
  if version_ge "$RUST_VER" "1.96"; then
    ok "rustc $RUST_VER"
  else
    warn "rustc $RUST_VER — requires 1.96+ (SurrealDB 3.2 plus wasm target). Run: rustup toolchain install 1.96"
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

TARGETS=$(rustup target list --installed 2>/dev/null || true)
for target in wasm32-unknown-unknown \
              aarch64-linux-android armv7-linux-androideabi x86_64-linux-android \
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

# Cargo tools (frb codegen must align with the crate version the workspace pins: 2.12)
check_cargo_tool() {
  local bin="$1" pkg="$2" want="${3:-}" ver_flag="${4:---version}"
  if command -v "$bin" &>/dev/null; then
    local have
    have=$($bin $ver_flag 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) || have=""
    if [[ -n "$want" ]] && [[ -n "$have" ]] && ! version_ge "$have" "$want"; then
      warn "$bin $have — requires $want+ (must align with the workspace's flutter_rust_bridge crate version)"
      MISSING+=("$pkg-update")
      if $INSTALL_MODE; then
        info "Upgrading $pkg to $want..."
        cargo install "$pkg" --version "^$want" --force && ok "$bin upgraded"
      fi
    else
      ok "$bin ($have)"
    fi
  else
    fail "$bin not found"
    MISSING+=("$pkg")
    if $INSTALL_MODE; then
      info "Installing $pkg..."
      cargo install "$pkg" ${want:+--version "^$want"} && ok "$bin installed"
    fi
  fi
}
check_cargo_tool "flutter_rust_bridge_codegen" "flutter_rust_bridge_codegen" "2.12"
check_cargo_tool "cargo-ndk" "cargo-ndk"
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

# Prometheus Skill System — operational gate (binaries + doctor + mcp health),
# not just presence. A FULL instance also brings self-improving loops (pmpo-outer-loop,
# Karpathy learning loop) and the pk knowledge CLI.
echo ""
echo "  Prometheus Skill System (full instance)"
PK_BINS_OK=true
for bin in prometheus forge pk pk-cherry liter-llm; do
  if command -v "$bin" &>/dev/null; then
    ok "  $bin present"
  else
    warn "  $bin missing"
    PK_BINS_OK=false
  fi
done
if command -v pk &>/dev/null && pk doctor --json &>/dev/null; then
  ok "  pk doctor: operational"
else
  warn "  pk doctor: not operational (or pk missing)"
  PK_BINS_OK=false
fi
if $PK_BINS_OK; then
  ok "  Prometheus Skill System: installed and operational"
else
  MISSING+=("prometheus-skill-system")
  if $INSTALL_MODE && $FULL_MODE; then
    info "  Installing Prometheus Skill System (full instance, this is a long operation)..."
    SKILL_SYS_HOME="${PROMETHEUS_SKILL_SYSTEM_HOME:-$HOME/.prometheus-skill-system}"
    if [[ ! -d "$SKILL_SYS_HOME" ]]; then
      git clone --recurse-submodules \
        https://github.com/Prometheus-AGS/prometheus-skill-system.git "$SKILL_SYS_HOME"
    fi
    (
      cd "$SKILL_SYS_HOME"
      bash scripts/check-prerequisites.sh --install --build-tools
      bash scripts/install-skills-flat.sh
      bash scripts/install-mcp-services.sh
      bash scripts/configure-mcp-all-tools.sh
      bash scripts/prometheus-services.sh load
    )
    ok "  Prometheus Skill System installed — verify with: pk doctor --json"
  elif $INSTALL_MODE; then
    warn "  Skipping full skill-system install (pass --full for this long operation)"
  fi
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# Pillar 2 — OpenSpec (latest, scoped npm name)
# ═══════════════════════════════════════════════════════════════════════════
pillar 2 "OpenSpec (spec execution engine)"

# The bare npm name "openspec" is a squatted 0.0.0 placeholder — the scoped
# package @fission-ai/openspec is the real project. Never install the bare name.
if command -v openspec &>/dev/null; then
  OS_VER=$(openspec --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) || OS_VER=""
  if version_ge "$OS_VER" "1.6.0"; then
    ok "openspec $OS_VER"
  else
    warn "openspec $OS_VER — behind latest (1.6.0+). Run: npm i -g @fission-ai/openspec@latest"
    MISSING+=("openspec-update")
    if $INSTALL_MODE; then
      info "Upgrading OpenSpec..."
      npm install -g @fission-ai/openspec@latest && ok "openspec upgraded"
    fi
  fi
else
  fail "OpenSpec not found"
  MISSING+=("openspec")
  if $INSTALL_MODE; then
    info "Installing @fission-ai/openspec (NOT the bare 'openspec' package — that's squatted)..."
    npm install -g @fission-ai/openspec@latest && ok "openspec installed"
  fi
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# Pillar 3 — Flutter/Dart BETA channel (ships the Dart MCP server)
# ═══════════════════════════════════════════════════════════════════════════
pillar 3 "Flutter/Dart beta channel (Dart MCP server)"

if command -v flutter &>/dev/null; then
  FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
  FLUTTER_CHANNEL=$(flutter --version 2>/dev/null | head -1 | grep -oE 'channel [a-z]+' | awk '{print $2}') || FLUTTER_CHANNEL=""
  if [[ "$FLUTTER_CHANNEL" == "beta" ]]; then
    ok "flutter $FLUTTER_VER (channel beta)"
  else
    warn "flutter on channel '${FLUTTER_CHANNEL:-unknown}' — this project requires beta"
    MISSING+=("flutter-channel")
    if $INSTALL_MODE; then
      info "Switching to beta channel..."
      flutter channel beta
      if $FULL_MODE; then
        info "Running flutter upgrade (long operation, multi-GB, 5-15 min)..."
        flutter upgrade && ok "Flutter upgraded on beta"
      else
        warn "Channel switched; run with --full to complete 'flutter upgrade' (long operation)"
      fi
    fi
  fi
  # Use Flutter's bundled Dart. A separately installed `dart` earlier on PATH
  # can be a different channel and cannot resolve Flutter SDK dependencies.
  FLUTTER_INFO=$(flutter --version --machine)
  FLUTTER_SDK_ROOT=$(printf '%s' "$FLUTTER_INFO" | python3 -c 'import json, sys; print(json.load(sys.stdin)["flutterRoot"])')
  FLUTTER_DART="$FLUTTER_SDK_ROOT/bin/cache/dart-sdk/bin/dart"
  DART_VER=$("$FLUTTER_DART" --version 2>/dev/null | awk '{print $4}')
  ok "Flutter-bundled dart $DART_VER"
  if "$FLUTTER_DART" mcp-server --help &>/dev/null; then
    ok "Flutter-bundled dart mcp-server: operational"
  else
    warn "Flutter-bundled dart mcp-server: not available (needs Dart 3.9+/Flutter 3.35+)"
  fi
else
  fail "Flutter not found"
  MISSING+=("flutter")
  if $INSTALL_MODE; then
    bash "$(dirname "$0")/install-flutter.sh"
  fi
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# Pillar 4 — Node 24 LTS + bun + pnpm + TypeScript (latest)
# ═══════════════════════════════════════════════════════════════════════════
pillar 4 "Node 24 LTS + bun + pnpm + TypeScript"

if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
  if [[ $NODE_MAJOR -ge 24 ]]; then
    ok "node $NODE_VER"
    ok "npm $(npm --version)"
  else
    warn "node $NODE_VER — requires 24+ (Active LTS through Apr 2028)"
    MISSING+=("node-update")
    if $INSTALL_MODE; then
      info "Installing fnm and Node 24 (pinned — 'lts' becomes Node 26 after Oct 2026)..."
      command -v fnm &>/dev/null || curl -fsSL https://fnm.vercel.app/install | bash
      export PATH="$HOME/.fnm:$PATH"; eval "$(fnm env)" 2>/dev/null || true
      fnm install 24 && fnm default 24 && fnm use 24
      ok "Node 24 installed"
    fi
  fi
else
  fail "Node.js not found"
  MISSING+=("node")
  if $INSTALL_MODE; then
    info "Installing fnm and Node 24..."
    curl -fsSL https://fnm.vercel.app/install | bash
    export PATH="$HOME/.fnm:$PATH"; eval "$(fnm env)" 2>/dev/null || true
    fnm install 24 && fnm default 24 && fnm use 24
    ok "Node 24 installed"
  fi
fi

if command -v bun &>/dev/null; then
  ok "bun $(bun --version)"
else
  warn "bun not found"
  MISSING+=("bun")
  if $INSTALL_MODE; then
    info "Installing bun..."
    curl -fsSL https://bun.sh/install | bash && ok "bun installed"
  fi
fi

if command -v pnpm &>/dev/null; then
  ok "pnpm $(pnpm --version)"
else
  warn "pnpm not found"
  MISSING+=("pnpm")
  if $INSTALL_MODE; then
    npm install -g pnpm && ok "pnpm installed"
  fi
fi

# TypeScript — this project tracks LATEST (7.x, Go-native compiler), not a pin.
TSC_BIN="$(command -v tsc 2>/dev/null || true)"
if [[ -n "$TSC_BIN" ]]; then
  TS_VER=$(tsc --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) || TS_VER=""
  if version_ge "$TS_VER" "7.0.0"; then
    ok "typescript $TS_VER"
  else
    warn "typescript $TS_VER — this project tracks latest (7.0.2+, Go-native compiler)"
    MISSING+=("typescript-update")
    if $INSTALL_MODE; then
      info "Installing typescript@latest..."
      npm install -g typescript@latest && ok "typescript upgraded"
    fi
  fi
else
  fail "TypeScript (tsc) not found globally"
  MISSING+=("typescript")
  if $INSTALL_MODE; then
    npm install -g typescript@latest && ok "typescript installed"
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

# Docker (surreal-memory service in the Prometheus Skill System)
if command -v docker &>/dev/null; then
  ok "docker present"
else
  warn "docker not found — needed for the Prometheus Skill System's surreal-memory service"
fi

# ── Summary ───────────────────────────────────────────────────────────────
# Re-check after remediation rather than trusting the pre-install $MISSING snapshot
# (items fixed during --install would otherwise still be reported as outstanding).
echo ""
if $INSTALL_MODE; then
  STILL_MISSING=()
  for item in "${MISSING[@]}"; do
    case "$item" in
      rust-update)       version_ge "$(rustc --version | awk '{print $2}' | cut -d- -f1)" "1.96" || STILL_MISSING+=("$item") ;;
      flutter_rust_bridge_codegen-update) version_ge "$(flutter_rust_bridge_codegen --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" "2.12" || STILL_MISSING+=("$item") ;;
      openspec-update)   version_ge "$(openspec --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" "1.6.0" || STILL_MISSING+=("$item") ;;
      node-update)       [[ $(node --version | sed 's/v//' | cut -d. -f1) -ge 24 ]] || STILL_MISSING+=("$item") ;;
      typescript-update|typescript) version_ge "$(tsc --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" "7.0.0" || STILL_MISSING+=("$item") ;;
      cargo-ndk)         command -v cargo-ndk &>/dev/null || STILL_MISSING+=("$item") ;;
      tauri-cli)         cargo tauri --version &>/dev/null 2>&1 || STILL_MISSING+=("$item") ;;
      pnpm|bun)          command -v "$item" &>/dev/null || STILL_MISSING+=("$item") ;;
      flutter-channel)   [[ "$(flutter --version 2>/dev/null | head -1 | grep -oE 'channel [a-z]+' | awk '{print $2}')" == "beta" ]] || STILL_MISSING+=("$item") ;;
      *)                 STILL_MISSING+=("$item") ;;  # unresolvable checks (rust, node, flutter presence, xcode, skill-system without --full)
    esac
  done
  MISSING=("${STILL_MISSING[@]}")
fi

if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo -e "${GREEN}✅ All four pillars present and operational. Ready to build.${NC}"
else
  echo -e "${YELLOW}⚠  Outstanding items: ${MISSING[*]}${NC}"
  echo ""
  if ! $INSTALL_MODE; then
    echo "  Run with --install to remediate:  bash scripts/check-env.sh --install"
    echo "  Add --full for long operations (Flutter upgrade, full skill-system install):"
    echo "  bash scripts/check-env.sh --install --full"
  elif ! $FULL_MODE; then
    echo "  Re-run with --full to complete long-running remediations:"
    echo "  bash scripts/check-env.sh --install --full"
  fi
fi
echo ""
