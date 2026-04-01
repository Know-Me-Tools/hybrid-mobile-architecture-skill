#!/usr/bin/env bash
# scripts/scaffold-hybrid.sh
# Scaffold a complete hybrid project: Flutter mobile + Tauri desktop + shared Rust core
# Usage: bash scripts/scaffold-hybrid.sh <project-name> [--org com.example] [--uar embedded|external]

set -euo pipefail

PROJECT="${1:-my-hybrid-app}"
ORG="${2:---org}"; ORG="${3:-ai.prometheusags}"
UAR_MODE="${5:-embedded}"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }

# Verify environment first
bash "$(dirname "$0")/check-env.sh" || { echo "Fix environment issues first."; exit 1; }

step "Creating workspace: $PROJECT"
mkdir -p "$PROJECT"/{rust,mobile,desktop,docs}
cd "$PROJECT"

# ── Root workspace config ──────────────────────────────────────────────────
cat > Cargo.toml << EOF
[workspace]
members = ["rust/gen_ui_core"]
resolver = "2"

[workspace.package]
version = "0.1.0"
edition = "2021"
rust-version = "1.80"

[workspace.dependencies]
tokio             = { version = "1.40", features = ["full"] }
tokio-stream      = { version = "0.1",  features = ["sync"] }
futures           = "0.3"
flutter_rust_bridge = { version = "2.3", features = ["dart-opaque", "anyhow"] }
reqwest           = { version = "0.12", features = ["json", "stream", "rustls-tls"], default-features = false }
reqwest-eventsource = "0.6"
serde             = { version = "1.0",  features = ["derive"] }
serde_json        = "1.0"
candle-core       = { version = "0.7",  features = ["metal", "accelerate"] }
candle-nn         = "0.7"
candle-transformers = "0.7"
hf-hub            = { version = "0.3",  features = ["tokio"] }
tokenizers        = { version = "0.20", features = ["http"] }
surrealdb         = { version = "2.0",  features = ["kv-rocksdb"] }
rayon             = "1.10"
dashmap           = "6.1"
parking_lot       = "0.12"
tracing           = "0.1"
anyhow            = "1.0"
thiserror         = "1.0"
uuid              = { version = "1.10", features = ["v4", "fast-rng"] }
chrono            = { version = "0.4",  features = ["serde"] }
once_cell         = "1.20"
async-trait       = "0.1"
EOF
ok "Rust workspace Cargo.toml"

# ── Scaffold Rust core ─────────────────────────────────────────────────────
step "Scaffolding gen_ui_core Rust crate"
bash "$(dirname "$0")/scaffold-rust-core.sh" "rust/gen_ui_core" "$UAR_MODE"
ok "gen_ui_core scaffolded"

# ── Scaffold Flutter app ───────────────────────────────────────────────────
step "Scaffolding Flutter mobile app"
bash "$(dirname "$0")/scaffold-flutter.sh" "mobile" "$PROJECT"
ok "Flutter app scaffolded in mobile/"

# ── Scaffold Tauri app ─────────────────────────────────────────────────────
step "Scaffolding Tauri desktop app"
bash "$(dirname "$0")/scaffold-tauri.sh" "desktop" "$PROJECT"
ok "Tauri app scaffolded in desktop/"

# ── Copy documentation ─────────────────────────────────────────────────────
step "Copying architecture documentation"
SKILL_DIR="$(dirname "$(dirname "$0")")"
if [[ -f "$SKILL_DIR/docs/tj-arch-mob-001.html" ]]; then
  cp "$SKILL_DIR/docs/tj-arch-mob-001.html" "docs/"
  ok "Architecture standard (TJ-ARCH-MOB-001) copied to docs/"
fi

# ── Root README ───────────────────────────────────────────────────────────
step "Writing root README"
cat > README.md << READMEEOF
# $PROJECT — Hybrid Mobile + Desktop Application

Built on the [Prometheus AGS Hybrid Mobile Architecture](docs/tj-arch-mob-001.html).

## Structure

\`\`\`
$PROJECT/
├── rust/gen_ui_core/   ← Shared Rust infrastructure (Tokio, Anthropic, inference, MCP, SurrealDB, UAR)
├── mobile/             ← Flutter iOS/Android application (Riverpod, gen_ui widgets)
├── desktop/            ← Tauri macOS/Windows/Linux application (React 19, Zustand, TanStack)
└── docs/               ← Architecture documentation
\`\`\`

## Quick start

\`\`\`bash
# Check environment
bash scripts/check-env.sh --install

# Build shared Rust core (Android)
bash scripts/android/build.sh release

# Build shared Rust core (iOS/macOS)
bash scripts/ios/build-xcframework.sh release

# Generate Flutter FFI bindings
flutter_rust_bridge_codegen generate \\
  --rust-input rust/gen_ui_core/src/api.rs \\
  --dart-output mobile/lib/bridge/generated_api.dart

# Run Flutter
cd mobile && flutter run

# Run Tauri desktop
cd desktop && pnpm tauri dev
\`\`\`

## Architecture Standard

See [TJ-ARCH-MOB-001](docs/tj-arch-mob-001.html) for platform selection criteria,
state management standards, and enforcement rules.
READMEEOF
ok "README.md written"

# ── .gitignore ────────────────────────────────────────────────────────────
cat > .gitignore << EOF
# Rust
target/
*.lock

# Flutter
mobile/.dart_tool/
mobile/build/
mobile/.flutter-plugins
mobile/.flutter-plugins-dependencies
mobile/android/app/src/main/jniLibs/
mobile/ios/Frameworks/

# Tauri/Node
desktop/node_modules/
desktop/src-tauri/target/
desktop/dist/

# Environment
.env
.env.*
!.env.example
EOF
ok ".gitignore"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Hybrid project scaffolded: $PROJECT  ${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo "  1. Set ANTHROPIC_API_KEY in .env (or --dart-define)"
echo "  2. bash scripts/check-env.sh --install"
echo "  3. Read docs/tj-arch-mob-001.html for architecture decisions"
echo "  4. cd mobile && flutter pub get && flutter run"
echo "  5. cd desktop && pnpm install && pnpm tauri dev"
echo ""
