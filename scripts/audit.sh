#!/usr/bin/env bash
# scripts/audit.sh
# Audit a codebase for TJ-ARCH-MOB-001 architectural compliance.
# Usage: bash scripts/audit.sh <platform: flutter|tauri|rust> [project-root]

set -euo pipefail

PLATFORM="${1:-flutter}"
ROOT="${2:-.}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
pass()  { echo -e "    ${GREEN}✓${NC} $1"; ((PASS_COUNT++)) || true; }
fail()  { echo -e "    ${RED}✗${NC} $1"; ((FAIL_COUNT++)) || true; ((VIOLATIONS++)) || true; }
warn()  { echo -e "    ${YELLOW}⚠${NC} $1"; ((WARN_COUNT++)) || true; }
check() { echo -e "  ${CYAN}→${NC} $1"; }

PASS_COUNT=0; FAIL_COUNT=0; WARN_COUNT=0; VIOLATIONS=0

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TJ-ARCH-MOB-001 Compliance Audit — $PLATFORM ${NC}"
echo -e "${CYAN}  $(date +%Y-%m-%d)                                  ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""

# ── Flutter audit ──────────────────────────────────────────────────────────
if [[ "$PLATFORM" == "flutter" ]]; then
  LIB="$ROOT/lib"
  [[ -d "$LIB" ]] || { echo "Error: $LIB not found"; exit 1; }

  echo -e "${CYAN}[01] Dependency checks (pubspec.yaml)${NC}"
  PUBSPEC="$ROOT/pubspec.yaml"
  if [[ -f "$PUBSPEC" ]]; then
    grep -q "flutter_riverpod:" "$PUBSPEC" && pass "flutter_riverpod present" || fail "flutter_riverpod MISSING — required"
    grep -q "riverpod_annotation:" "$PUBSPEC" && pass "riverpod_annotation present" || fail "riverpod_annotation MISSING"
    grep -q "freezed_annotation:" "$PUBSPEC" && pass "freezed_annotation present" || warn "freezed_annotation not found"
    grep -q "flutter_rust_bridge:" "$PUBSPEC" && pass "flutter_rust_bridge present" || warn "flutter_rust_bridge not found (required when gen_ui_core is wired)"
    grep -q "shadcn_flutter:" "$PUBSPEC" && pass "shadcn_flutter present (shadcn equivalent)" || warn "shadcn_flutter not found — consider adding"
    grep -q "go_router:" "$PUBSPEC" && pass "go_router present" || warn "go_router not found"
    grep -q "provider:" "$PUBSPEC" && fail "provider package found — use Riverpod only" || pass "provider package not present ✓"
    grep -q "bloc:" "$PUBSPEC" && fail "bloc package found — use Riverpod only" || pass "bloc package not present ✓"
    grep -q "setState\|StatefulWidget" "$LIB/features" 2>/dev/null && warn "StatefulWidget usage found — prefer ConsumerStatefulWidget or hooks" || true
  else
    fail "pubspec.yaml not found"
  fi

  echo ""
  echo -e "${CYAN}[02] Feature-based clean architecture${NC}"
  if [[ -d "$LIB/features" ]]; then
    pass "features/ directory exists"
    for feature in "$LIB/features"/*/; do
      fname="$(basename "$feature")"
      [[ -d "$feature/data" ]]         && pass "  $fname/data/" || warn "  $fname/data/ missing"
      [[ -d "$feature/domain" ]]       && pass "  $fname/domain/" || fail "  $fname/domain/ MISSING — required"
      [[ -d "$feature/presentation" ]] && pass "  $fname/presentation/" || fail "  $fname/presentation/ MISSING"
    done
  else
    fail "features/ directory MISSING — feature-based arch required"
  fi

  [[ -d "$LIB/core" ]]   && pass "core/ directory exists" || warn "core/ directory missing"
  [[ -d "$LIB/shared" ]] && pass "shared/ directory exists" || warn "shared/ directory missing"
  [[ -d "$LIB/bridge" ]] && pass "bridge/ directory exists" || warn "bridge/ directory missing (required for Rust FFI)"

  echo ""
  echo -e "${CYAN}[03] Riverpod pattern compliance${NC}"
  # Check for codegen annotations
  if find "$LIB" -name "*.dart" | xargs grep -l "@riverpod\|@Riverpod" 2>/dev/null | head -1 | grep -q .; then
    pass "@riverpod codegen annotations found"
  else
    warn "@riverpod codegen annotations not found — use codegen, not manual providers"
  fi
  # Check for manual StateNotifierProvider (deprecated pattern)
  if grep -r "StateNotifierProvider\|ChangeNotifierProvider" "$LIB" 2>/dev/null | grep -v ".g.dart" | grep -q .; then
    fail "StateNotifierProvider/ChangeNotifierProvider found — use @riverpod codegen"
  else
    pass "No deprecated provider patterns found"
  fi

  echo ""
  echo -e "${CYAN}[04] Business logic boundary${NC}"
  # Check for HTTP calls in presentation layer
  if grep -r "http\.\|dio\.\|Dio(" "$LIB/features" 2>/dev/null | grep -E "presentation/|screens/|widgets/" | grep -v ".g.dart" | grep -q .; then
    fail "HTTP calls found in presentation layer — move to data/repositories"
  else
    pass "No HTTP calls in presentation layer"
  fi
  # Check for invoke() in Flutter (should be in Rust, not Dart HTTP)
  if grep -r "import 'package:http/" "$LIB/features" 2>/dev/null | grep -E "presentation/" | grep -q .; then
    fail "http package imported in presentation — use repository pattern"
  else
    pass "HTTP package not imported in presentation layer"
  fi

  echo ""
  echo -e "${CYAN}[05] Code generation artifacts${NC}"
  if find "$LIB" -name "*.g.dart" | head -1 | grep -q .; then
    pass "Code generation artifacts (.g.dart) present"
  else
    warn "No .g.dart files found — run: dart run build_runner build"
  fi
  if find "$LIB" -name "*.freezed.dart" | head -1 | grep -q .; then
    pass "Freezed artifacts (.freezed.dart) present"
  else
    warn "No .freezed.dart files found — run: dart run build_runner build"
  fi

  echo ""
  echo -e "${CYAN}[06] gen_ui_core FFI bridge${NC}"
  if [[ -f "$LIB/bridge/rust_bridge_provider.dart" ]]; then
    pass "bridge/rust_bridge_provider.dart present"
    grep -q "import 'generated_api.dart'" "$LIB/bridge/rust_bridge_provider.dart" && pass "FFI import wired" || warn "FFI import not yet wired (uncomment after frb codegen)"
  else
    warn "bridge/rust_bridge_provider.dart not found"
  fi

# ── Tauri/React audit ─────────────────────────────────────────────────────
elif [[ "$PLATFORM" == "tauri" ]]; then
  SRC="$ROOT/src"
  [[ -d "$SRC" ]] || { echo "Error: $SRC not found"; exit 1; }

  echo -e "${CYAN}[01] Dependency checks (package.json)${NC}"
  PKG="$ROOT/package.json"
  if [[ -f "$PKG" ]]; then
    grep -q '"zustand"'                && pass "zustand present" || fail "zustand MISSING — required"
    grep -q '"@tanstack/react-query"'  && pass "@tanstack/react-query present" || fail "@tanstack/react-query MISSING"
    grep -q '"@tanstack/react-router"' && pass "@tanstack/react-router present" || fail "@tanstack/react-router MISSING"
    grep -q '"@tanstack/react-table"'  && pass "@tanstack/react-table present" || warn "@tanstack/react-table not found"
    grep -q '"@tauri-apps/api"'        && pass "@tauri-apps/api present" || fail "@tauri-apps/api MISSING"
    grep -q '"immer"'                  && pass "immer present" || warn "immer not found — recommended for Zustand"
    grep -q '"redux\|@reduxjs'         && fail "Redux found — use Zustand" || pass "Redux not present ✓"
    grep -q '"jotai\|recoil'           && fail "jotai/recoil found — use Zustand" || pass "jotai/recoil not present ✓"
    grep -q '"react-router'            && fail "react-router found — use TanStack Router" || pass "react-router not present ✓"
  else
    fail "package.json not found"
  fi < "$PKG"

  echo ""
  echo -e "${CYAN}[02] Feature-based clean architecture${NC}"
  if [[ -d "$SRC/features" ]]; then
    pass "features/ directory exists"
    for feature in "$SRC/features"/*/; do
      fname="$(basename "$feature")"
      [[ -d "$feature/api" ]]        && pass "  $fname/api/" || warn "  $fname/api/ missing"
      [[ -d "$feature/stores" ]]     && pass "  $fname/stores/" || fail "  $fname/stores/ MISSING"
      [[ -d "$feature/queries" ]]    && pass "  $fname/queries/" || warn "  $fname/queries/ missing (server-side state)"
      [[ -d "$feature/hooks" ]]      && pass "  $fname/hooks/" || fail "  $fname/hooks/ MISSING — required for layer contract"
      [[ -d "$feature/components" ]] && pass "  $fname/components/" || fail "  $fname/components/ MISSING"
    done
  else
    fail "features/ directory MISSING"
  fi

  echo ""
  echo -e "${CYAN}[03] Layer contract enforcement${NC}"
  # Components should not import stores directly
  if grep -r "useXxxStore\|from.*stores/" "$SRC/features" 2>/dev/null | grep -E "components/|\.tsx:" | grep -v "hooks/" | grep -q "Store\|from.*stores"; then
    fail "Store imports found in component files — components must use hooks only"
    echo "    Violations:"
    grep -r "from.*stores/" "$SRC/features" 2>/dev/null | grep -E "components/.*\.tsx:" | head -5 | sed 's/^/      /'
  else
    pass "No direct store imports in component files"
  fi

  # Components/hooks should not call invoke() directly
  if grep -r "invoke(" "$SRC/features" 2>/dev/null | grep -E "components/|hooks/" | grep -q "invoke("; then
    fail "invoke() found in components or hooks — move to stores/api layers"
    grep -r "invoke(" "$SRC/features" 2>/dev/null | grep -E "components/|hooks/" | head -5 | sed 's/^/    /'
  else
    pass "No invoke() calls in components or hooks ✓"
  fi

  # Hooks should not call fetch() or API directly
  if grep -r "^import.*fetch\|await fetch(" "$SRC/features" 2>/dev/null | grep "hooks/" | grep -q fetch; then
    fail "fetch() found in hooks — calls to external APIs belong in stores or api/"
  else
    pass "No direct fetch() in hooks ✓"
  fi

  echo ""
  echo -e "${CYAN}[04] TanStack Query usage${NC}"
  if grep -r "useQuery\|useMutation" "$SRC/features" 2>/dev/null | grep -q "useQuery\|useMutation"; then
    pass "TanStack Query hooks in use"
    # Verify in queries/ not components
    if grep -r "useQuery\|useMutation" "$SRC/features" 2>/dev/null | grep -E "components/.*\.tsx:" | grep -q "useQuery"; then
      warn "useQuery/useMutation in component files — prefer composing via feature hooks"
    fi
  else
    warn "No TanStack Query hooks found — ensure server-side state uses useQuery"
  fi

  echo ""
  echo -e "${CYAN}[05] Tauri IPC bridge${NC}"
  if [[ -f "$SRC/bridge/a2ui/types.ts" ]]; then
    pass "bridge/a2ui/types.ts present"
  else
    warn "bridge/a2ui/types.ts not found — required for A2UI streaming"
  fi
  if grep -r "listen(" "$SRC" 2>/dev/null | grep -v "node_modules" | grep -q "a2ui_event"; then
    pass "a2ui_event listener wired"
  else
    warn "a2ui_event listener not found — wire in store init"
  fi

# ── Rust audit ─────────────────────────────────────────────────────────────
elif [[ "$PLATFORM" == "rust" ]]; then
  [[ -d "$ROOT/src" ]] || { echo "Error: $ROOT/src not found"; exit 1; }

  echo -e "${CYAN}[01] Module structure${NC}"
  for mod in api api_http runtime streaming config protocol agent inference mcp db; do
    if [[ -f "$ROOT/src/$mod.rs" ]] || [[ -d "$ROOT/src/$mod" ]]; then
      pass "$mod module present"
    else
      warn "$mod module missing"
    fi
  done

  echo ""
  echo -e "${CYAN}[02] Runtime invariants${NC}"
  if grep -q "OnceLock\|once_cell" "$ROOT/src/runtime.rs" 2>/dev/null; then
    pass "Global runtime uses OnceLock singleton pattern"
  else
    warn "Runtime singleton pattern not detected"
  fi
  if grep -r "tokio::runtime::Builder::new_multi_thread" "$ROOT/src" 2>/dev/null | grep -q .; then
    pass "Multi-thread Tokio runtime configured"
  else
    warn "Multi-thread runtime not found"
  fi
  if grep -r "spawn_blocking" "$ROOT/src" 2>/dev/null | grep -q .; then
    pass "spawn_blocking used for CPU-bound work"
  else
    warn "No spawn_blocking found — ensure inference uses blocking pool"
  fi

  echo ""
  echo -e "${CYAN}[03] Protocol pipeline${NC}"
  [[ -f "$ROOT/src/protocol/a2ui.rs" ]] && pass "A2UI adapter present" || fail "A2UI adapter MISSING"
  [[ -f "$ROOT/src/protocol/agui.rs" ]] && pass "AG-UI adapter present" || fail "AG-UI adapter MISSING"
  grep -q "broadcast::channel\|broadcast::Sender" "$ROOT/src/protocol/mod.rs" 2>/dev/null && pass "Broadcast channels in pipeline" || warn "Broadcast channels not found in protocol/mod.rs"

  echo ""
  echo -e "${CYAN}[04] Build targets${NC}"
  grep -q "cdylib\|staticlib" "$ROOT/Cargo.toml" 2>/dev/null && pass "Both cdylib and staticlib crate-types present" || warn "Check crate-type = [\"cdylib\", \"staticlib\"]"
fi

# ── Summary ───────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "  Audit complete — $PLATFORM"
echo -e "  ${GREEN}PASS: $PASS_COUNT${NC}  ${YELLOW}WARN: $WARN_COUNT${NC}  ${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""

if [[ $VIOLATIONS -gt 0 ]]; then
  echo -e "${RED}  ✗ $VIOLATIONS violation(s) found — fix before merging${NC}"
  echo ""
  exit 1
else
  echo -e "${GREEN}  ✓ No violations — compliant with TJ-ARCH-MOB-001${NC}"
  echo ""
fi
