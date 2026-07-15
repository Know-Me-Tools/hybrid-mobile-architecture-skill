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

# ── Scaffold the layered gen_ui Rust workspace ─────────────────────────────
# The workspace Cargo.toml (root, profiles, workspace.dependencies) and all 12
# crates are emitted by scaffold-rust-core.sh — it owns the layered layout,
# compile-speed profiles (panic=unwind for FFI, wasm-release), and .cargo/bacon
# config. Do NOT inline a workspace manifest here; that duplicated the source of
# truth and drifted (old single-crate layout, surrealdb 2.0, panic=abort bug).
step "Scaffolding layered gen_ui workspace"
bash "$(dirname "$0")/scaffold-rust-core.sh" "rust" "$UAR_MODE"
ok "gen_ui workspace scaffolded (12 crates, layered)"

# ── Scaffold Flutter app ───────────────────────────────────────────────────
step "Scaffolding Flutter mobile app"
bash "$(dirname "$0")/scaffold-flutter.sh" "mobile" "$PROJECT"
ok "Flutter app scaffolded in mobile/"

# ── Scaffold Tauri app ─────────────────────────────────────────────────────
step "Scaffolding Tauri desktop app"
bash "$(dirname "$0")/scaffold-tauri.sh" "desktop" "$PROJECT"
ok "Tauri app scaffolded in desktop/"

# ── Scaffold publishable packages (C-007) ──────────────────────────────────
# npm (gen-ui-react, gen-ui-wasm, tauri-plugin-gen-ui guest-js) + pub.dev
# (gen_ui_flutter, gen_ui_widgets). Structured for publication from day one.
step "Scaffolding publishable packages"
bash "$(dirname "$0")/scaffold-packages.sh" "."
ok "Package skeletons scaffolded (npm + pub.dev)"

# ── Project-local UI/UX skills + activation hook (C-009) ───────────────────
# Emits templates/project-skills into the new project's .claude/skills + a
# UserPromptSubmit activation hook (raises skill hit-rate ~50% -> ~84-100%).
step "Installing project-local UI/UX skills"
bash "$(dirname "$0")/add-project-skills.sh" "." || echo "  (skills step skipped)"

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
├── rust/               ← Shared layered Rust workspace (gen_ui_core + leaves: ffi, tauri-plugin, wasm)
├── mobile/             ← Flutter iOS/Android application (Riverpod, gen_ui widgets)
├── desktop/            ← Tauri macOS/Windows/Linux application (React 19, Zustand, TanStack)
├── packages/           ← Publishable npm packages (@prometheus-ags/gen-ui-react, gen-ui-wasm)
├── flutter_packages/   ← Publishable pub.dev packages (gen_ui_flutter FFI plugin, gen_ui_widgets)
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

# Publishable packages (C-007)
packages/*/node_modules/
packages/*/dist/
packages/gen-ui-wasm/pkg/
rust/crates/tauri-plugin-gen-ui/guest-js/node_modules/
rust/crates/tauri-plugin-gen-ui/guest-js/dist/
flutter_packages/*/.dart_tool/
flutter_packages/*/build/

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
